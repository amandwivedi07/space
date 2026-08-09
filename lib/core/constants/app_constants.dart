/// App-wide constants: storage keys, sizes, durations.
class AppConstants {
  AppConstants._();

  /// Presence — the green/amber dot, the "HERE NOW" tile badges and the
  /// "N HERE NOW" pill on home. Switched off for now at Aman's request; flip
  /// this one flag back to true to bring all of them back at once. It is a
  /// flag rather than commented-out code so the widgets stay compiled and
  /// cannot rot while they are hidden.
  static const bool showPresence = false;

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
