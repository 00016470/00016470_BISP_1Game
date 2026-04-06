class AppConstants {
  AppConstants._();

  static const String baseUrl = 'http://localhost:8000';
  static const String apiPrefix = '/api';

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';

  static const String clubsEndpoint = '/clubs';
  static const String slotsEndpoint = '/slots';

  static const String bookingsEndpoint = '/bookings';
  static const String cancelEndpoint = '/cancel';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  static const Duration cacheDuration = Duration(minutes: 5);

  static const int backgroundPrimary = 0xFF1A1A2E;
  static const int backgroundSecondary = 0xFF16213E;
  static const int primaryAccent = 0xFF00E5FF;
  static const int successColor = 0xFF76FF03;
  static const int errorColor = 0xFFFF1744;
  static const int warningColor = 0xFFFF9100;
  static const int surfaceColor = 0xFF0F3460;
  static const int cardColor = 0xFF1A1A3E;
}
