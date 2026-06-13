/// Application-wide constants for configuration, API endpoints, and UI colors.
/// This class contains all the static constants used throughout the app,
/// including API URLs, authentication keys, cache durations, and color values.
class AppConstants {
  AppConstants._();

  /// The base URL for the API server.
  /// Can be overridden with environment variable BASE_URL.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://1game-api-production.up.railway.app',
  );

  /// The API prefix for all API endpoints.
  static const String apiPrefix = '/api';

  /// Authentication endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';

  /// Clubs and slots endpoints
  static const String clubsEndpoint = '/clubs';
  static const String slotsEndpoint = '/slots';

  /// Bookings endpoints
  static const String bookingsEndpoint = '/bookings';
  static const String cancelEndpoint = '/cancel';

  /// Secure storage keys for authentication tokens and user data
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  /// Duration for which data is cached in memory.
  static const Duration cacheDuration = Duration(minutes: 5);

  /// Primary background color (dark blue).
  static const int backgroundPrimary = 0xFF1A1A2E;

  /// Secondary background color (darker blue).
  static const int backgroundSecondary = 0xFF16213E;

  /// Primary accent color (cyan).
  static const int primaryAccent = 0xFF00E5FF;

  /// Success color (green).
  static const int successColor = 0xFF76FF03;

  /// Error color (red).
  static const int errorColor = 0xFFFF1744;

  /// Warning color (orange).
  static const int warningColor = 0xFFFF9100;

  /// Surface color for elevated elements.
  static const int surfaceColor = 0xFF0F3460;

  /// Card background color.
  static const int cardColor = 0xFF1A1A3E;
}
