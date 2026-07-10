/// App-wide constants: storage keys, sizes, durations.
class AppConstants {
  AppConstants._();

  static const String appName = 'Space';
  static const String tagline = 'a place where conversations are temporary';

  // Local storage keys (mirror the web app's namespacing).
  static const String profileKey = 'space.profile.v1';
  static const String themeKey = 'space.theme.v1';
  static const String defaultFadeKey = 'space.defaultFade.v1';
  static const String onboardedKey = 'space.onboarded.v1';

  // Cluster bubble sizes (dp).
  static const double bubbleSm = 64;
  static const double bubbleMd = 84;
  static const double bubbleLg = 108;
  static const double bubbleXl = 132;

  // Motion.
  static const Duration driftPeriod = Duration(seconds: 14);
  static const Duration sheetAnimation = Duration(milliseconds: 320);
  static const Duration fadeTick = Duration(seconds: 1);

  // Chat.
  static const int maxComposerLines = 5;
  static const Duration mockReplyDelay = Duration(seconds: 6);
  static const Duration mockAiDelay = Duration(milliseconds: 2600);
}
