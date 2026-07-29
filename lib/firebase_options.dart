// Generated from the Firebase project "space-chat" (space-chat-9a160).
// Regenerate with `flutterfire configure` or by re-downloading the config
// files and updating the values below.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Space Chat.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Space Chat has no web app configured yet.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform.',
        );
    }
  }

  /// Google Sign-In server client id (the Firebase "web" OAuth client).
  /// Android needs only this; it resolves its own client from
  /// google-services.json plus the signing certificate.
  static const String googleServerClientId =
      '809605119374-664lv2t0bokdatl8oujmpn9ibacraka7.apps.googleusercontent.com';

  /// Apple platforms must be told their own OAuth client explicitly —
  /// google_sign_in 7 does not read it from GoogleService-Info.plist.
  static const String googleIosClientId =
      '809605119374-16u26mbpic69rctqrrp2jgq3phldm6tb.apps.googleusercontent.com';

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAzLDydvTMr6_I_roSaIXC6ic72YHSGknQ',
    appId: '1:809605119374:android:830728feefe0ab5969f8df',
    messagingSenderId: '809605119374',
    projectId: 'space-chat-9a160',
    storageBucket: 'space-chat-9a160.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-1yKXRW0QAbhxLD27tdcm0hSvSwlGi5w',
    appId: '1:809605119374:ios:bf67c3c130e5abeb69f8df',
    messagingSenderId: '809605119374',
    projectId: 'space-chat-9a160',
    storageBucket: 'space-chat-9a160.firebasestorage.app',
    iosBundleId: 'com.talkinspace.talkinspace',
    iosClientId: '809605119374-16u26mbpic69rctqrrp2jgq3phldm6tb.apps.googleusercontent.com',
  );
}
