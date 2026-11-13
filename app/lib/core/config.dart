/// App-wide configuration.
///
/// [apiBaseUrl] points at YOUR backend (the one in ../backend). Override it at
/// build time without editing code:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/v1
///
/// Notes on host addresses during local development:
///   * Android emulator  -> http://10.0.2.2:8080/v1   (10.0.2.2 == host machine)
///   * iOS simulator     -> http://localhost:8080/v1
///   * Real device       -> http://<your-computer-LAN-IP>:8080/v1
class AppConfig {
  // For a USB-connected phone, run `adb reverse tcp:8080 tcp:8080` once; then the
  // phone's localhost:8080 maps to your Mac's backend. Override at build time:
  //   flutter run --dart-define=API_BASE_URL=http://<host>:8080/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/v1',
  );

  static const List<String> supportedLanguages = ['en', 'ta', 'hi'];
  static const String defaultLanguage = 'en';

  /// Network timeout for API calls. Generous so a hosted free-tier backend
  /// (e.g. Render) waking from idle — a ~30–60s cold start — doesn't fail the
  /// first request.
  static const Duration apiTimeout = Duration(seconds: 60);
}
