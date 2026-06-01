/// App-wide configuration constants
class AppConfig {
  // ─── API Configuration ─────────────────────────────────────────────────────
  // Change this to your server's IP/domain
  // For Android emulator use: 10.0.2.2
  // For iOS simulator use: localhost
  // For physical device use: your PC's local IP (e.g. 192.168.1.x)
  static const String baseUrl = 'http://192.168.43.219:3000';
  static const String apiUrl = '$baseUrl/api';
  static const String socketUrl = baseUrl;

  // ─── Pagination ────────────────────────────────────────────────────────────
  static const int messagesPerPage = 20;

  // ─── Storage Keys ──────────────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // ─── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
