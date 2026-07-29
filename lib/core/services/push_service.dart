import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'logger_service.dart';

/// FCM registration + routing.
///
/// The server sends DATA-ONLY payloads ({space_id, kind}) with a generic
/// "Something is waiting on Space" body — card content never leaves the app,
/// because it is ephemeral. Tapping a notification deep-links to the room.
///
/// Firebase must be configured per platform (GoogleService-Info.plist /
/// google-services.json). Without it, [initialize] logs and no-ops so the app
/// still runs — push is an enhancement, never a hard dependency.
class PushService {
  PushService(this._api);

  final ApiClient _api;

  String? _token;
  bool _available = false;

  /// Route target set when a notification is tapped (the space id).
  String? pendingSpaceId;

  /// Called when a tap should navigate; assigned by the app shell.
  void Function(String spaceId)? onOpenSpace;

  String? get token => _token;
  bool get available => _available;

  /// Boots Firebase and asks for permission. Safe to call when Firebase is
  /// not configured — it simply stays disabled.
  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      Log.w('push: Firebase not initialised, notifications disabled');
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        Log.d('push: permission denied');
        return;
      }
      if (Platform.isIOS) {
        // Without an APNs token, getToken() throws on iOS.
        await messaging.getAPNSToken();
      }
      _token = await messaging.getToken();
      _available = _token != null;

      // A rotated token must be re-registered or delivery silently stops.
      messaging.onTokenRefresh.listen((fresh) {
        _token = fresh;
        registerWithBackend();
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleTap(initial);
    } catch (e) {
      Log.w('push: initialization failed: $e');
    }
  }

  void _handleTap(RemoteMessage message) {
    final spaceId = message.data['space_id'] as String?;
    if (spaceId == null || spaceId.isEmpty) return;
    pendingSpaceId = spaceId;
    onOpenSpace?.call(spaceId);
  }

  /// Registers this device against the signed-in account.
  Future<void> registerWithBackend() async {
    final token = _token;
    if (token == null) return;
    try {
      await _api.post('/me/devices', body: {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'push_token': token,
      });
      Log.d('push: device registered');
    } on ApiException catch (e) {
      Log.w('push: device registration failed: $e');
    }
  }

  /// Stops delivery to this device (sign-out / account deletion).
  Future<void> unregisterFromBackend() async {
    final token = _token;
    if (token == null) return;
    try {
      await _api.delete('/me/devices/$token');
    } on ApiException catch (e) {
      Log.w('push: unregister failed: $e');
    }
  }
}

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(ref.watch(apiClientProvider)),
);
