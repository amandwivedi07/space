import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'logger_service.dart';

/// Draws the banner for a push that arrives while the app is on screen.
///
/// Background and terminated delivery needs nothing from this class: the
/// server sends a `notification` block alongside its data, so the OS draws
/// that itself and tapping it wakes the app through FirebaseMessaging.
/// Foreground is the gap — FCM hands a message straight to the app and
/// suppresses the system banner, on the assumption that an app already in
/// front will render it. On Android that means posting one ourselves; on iOS
/// it takes only telling APNs to present it anyway, which avoids a second
/// notification sitting underneath the first.
class NotificationDisplay {
  NotificationDisplay._();

  static final NotificationDisplay instance = NotificationDisplay._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Must match `AndroidNotification.ChannelID` on the server, the
  /// `default_notification_channel_id` meta-data, and MainActivity.
  static const channelId = 'space_talk_cards';

  bool _ready = false;
  int _nextId = 0;

  /// Called with the push data when one of our own banners is tapped.
  void Function(Map<String, dynamic> data)? onTap;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      // iOS asks for permission through firebase_messaging already; asking
      // again here would put a second system dialog in front of the user.
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onResponse,
      );

      if (Platform.isAndroid) {
        // Created here as well as in MainActivity: this is the definition the
        // notification is actually posted against, and creating a channel that
        // already exists with the same settings is a no-op.
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
              channelId,
              'Messages',
              description: 'Someone is waiting on Space',
              // HIGH, not DEFAULT: a card fades, so a notice the reader does
              // not see until they next unlock is worth very little.
              importance: Importance.high,
            ));
      }

      if (Platform.isIOS) {
        // Let APNs present the banner while the app is in front, rather than
        // posting a local copy — one notification, drawn by the system.
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      _ready = true;
    } catch (e) {
      Log.w('notifications: display setup failed: $e');
    }
  }

  /// Posts a foreground banner for [message]. A no-op on iOS, where the system
  /// has already been told to present it.
  Future<void> show(RemoteMessage message) async {
    if (!_ready || !Platform.isAndroid) return;
    final notification = message.notification;
    // The body is deliberately generic ("Something is waiting on Space") —
    // card content is ephemeral and must never come to rest in a notification
    // shade, so we show whatever the server chose to say and nothing more.
    final title = notification?.title ?? 'Space';
    final body = notification?.body ?? 'Something is waiting on Space';
    try {
      await _plugin.show(
        id: _nextId++,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Messages',
            channelDescription: 'Someone is waiting on Space',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      Log.w('notifications: show failed: $e');
    }
  }

  void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) onTap?.call(data);
    } catch (e) {
      Log.w('notifications: bad tap payload: $e');
    }
  }
}
