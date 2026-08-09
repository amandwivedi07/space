import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'logger_service.dart';
import 'notification_display.dart';

/// Runs in its own isolate when a push lands with the app backgrounded or
/// terminated. It must exist and must be a top-level function or FCM will not
/// wake the app at all on Android.
///
/// It deliberately draws nothing: the server pairs its data with a
/// `notification` block, so the system has already posted the banner by the
/// time this runs, and posting a second one here would show every message
/// twice. Keep it that way unless the payload ever becomes data-only.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

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

  /// Called when a tap should navigate; assigned by the app shell. [spaceKind]
  /// is "direct" or "circle" — a circle opened as a person room is a broken
  /// screen, so it has to travel with the id.
  void Function(String spaceId, String spaceKind)? onOpenSpace;

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
      // Registered before permission is asked for: the handler is picked up at
      // plugin start-up, not when the first message arrives.
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        Log.d('push: permission denied');
        return;
      }
      // Delivery is wired up BEFORE the token is fetched, and in its own
      // block. getToken() throws on the iOS simulator and on any iPhone until
      // an APNs key is uploaded to Firebase; with these after it, one throw
      // took the banner and the tap handler down with it and the app went
      // quiet even for messages that did arrive.
      final display = NotificationDisplay.instance;
      display.onTap = _openFrom;
      await display.initialize();
      FirebaseMessaging.onMessage.listen(display.show);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleTap(initial);
    } catch (e) {
      Log.w('push: initialization failed: $e');
    }

    try {
      final messaging = FirebaseMessaging.instance;
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
    } catch (e) {
      Log.w('push: no token, this device cannot be pushed to: $e');
    }
  }

  void _handleTap(RemoteMessage message) => _openFrom(message.data);

  void _openFrom(Map<String, dynamic> data) {
    final spaceId = data['space_id'] as String?;
    // A broadcast reaches many spaces at once, so it names none of them and
    // the tap simply opens the app on home.
    if (spaceId == null || spaceId.isEmpty) return;
    pendingSpaceId = spaceId;
    onOpenSpace?.call(spaceId, data['space_kind'] as String? ?? 'direct');
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
