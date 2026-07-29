import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/logger_service.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'token_storage.dart';

/// One WebSocket per app session. The server pushes small change events
/// ({"type":"cards.changed","space_id":…} / {"type":"spaces.changed"});
/// repositories listen and refetch over REST. Reconnects with backoff and
/// refreshes the access token when the upgrade is rejected.
class RealtimeClient {
  RealtimeClient(this._tokens, this._api);

  final TokenStorage _tokens;
  final ApiClient _api;

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _backoffSeconds = 2;
  bool _disposed = false;
  bool _connecting = false; // guards overlapping connect() calls
  bool _wantConnection = false; // false after an explicit disconnect()

  /// Server events. Listen and refetch — payloads are intentionally tiny.
  Stream<Map<String, dynamic>> get events => _events.stream;

  static String get _wsUrl {
    final base = ApiConfig.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/ws';
  }

  /// Connect (or reconnect). Safe to call repeatedly — overlapping calls and
  /// duplicate sockets are prevented by [_connecting].
  Future<void> connect() async {
    if (_disposed || _connecting) return;
    _connecting = true;
    _wantConnection = true;
    try {
      await _tokens.restore();
      final token = _tokens.accessToken;
      if (token == null) return; // no session yet — auth layer calls again

      await _teardownSocket();
      final channel =
          WebSocketChannel.connect(Uri.parse('$_wsUrl?token=$token'));
      await channel.ready;
      if (_disposed || !_wantConnection) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _backoffSeconds = 2;
      Log.d('realtime connected');

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 55), (_) {
        _channel?.sink.add(jsonEncode({'type': 'presence.ping'}));
      });

      _socketSub = channel.stream.listen(
        (raw) {
          if (_disposed || _events.isClosed) return;
          try {
            _events.add(jsonDecode(raw as String) as Map<String, dynamic>);
          } catch (_) {/* ignore malformed frames */}
        },
        // Only the CURRENT socket may trigger a reconnect; a socket we
        // deliberately replaced must not tear down its successor.
        onDone: () => _handleDrop(channel),
        onError: (_) => _handleDrop(channel),
      );
    } catch (e) {
      Log.w('realtime connect failed: $e');
      // Possibly an expired access token: any authed REST call refreshes it.
      try {
        await _api.get('/auth/me');
      } catch (_) {}
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _handleDrop(WebSocketChannel dropped) {
    if (!identical(dropped, _channel)) return; // stale socket — ignore
    _channel = null;
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || !_wantConnection) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _backoffSeconds), connect);
    _backoffSeconds = (_backoffSeconds * 2).clamp(2, 30);
  }

  Future<void> _teardownSocket() async {
    _pingTimer?.cancel();
    final sub = _socketSub;
    _socketSub = null;
    await sub?.cancel(); // cancel BEFORE closing: no onDone from our own close
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
  }

  /// Close the socket and stay closed (sign-out).
  Future<void> disconnect() async {
    _wantConnection = false;
    _reconnectTimer?.cancel();
    await _teardownSocket();
  }

  void dispose() {
    _disposed = true;
    _wantConnection = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    _events.close();
  }
}

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(
    ref.watch(tokenStorageProvider),
    ref.watch(apiClientProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});
