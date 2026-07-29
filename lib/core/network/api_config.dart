/// API endpoint configuration.
///
/// Defaults to production, so a plain `flutter build` ships something that
/// works. Point it at a local backend while developing:
///
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
///
/// The Android emulator reaches the host as 10.0.2.2, not localhost.
class ApiConfig {
  ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.spacechatapp.com/api/v1',
  );

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);
}
