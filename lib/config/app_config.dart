/// App-wide settings.
///
/// Change them without editing code by passing --dart-define when you run:
///   flutter run --dart-define=USE_MOCK=false --dart-define=API_URL=http://10.0.2.2:8080
class AppConfig {
  AppConfig._();

  /// Base URL of the Spring Boot backend (no trailing slash).
  /// - Android emulator -> http://10.0.2.2:8080 (your PC's localhost)
  /// - iOS simulator / desktop / web -> http://localhost:8080
  /// - Real phone -> http://<your PC's Wi-Fi IP>:8080
  static const String apiBaseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  /// true  = the app uses built-in sample data (no backend needed).
  /// false = the app calls the Spring Boot backend at [apiBaseUrl].
  static const bool useMock =
      bool.fromEnvironment('USE_MOCK', defaultValue: true);

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Days a donor must wait between donations.
  static const int donationCooldownDays = 56;

  /// Minimum age to register as a donor.
  static const int minimumAge = 17;

  /// OTP resend countdown in seconds.
  static const int otpResendSeconds = 45;
}
