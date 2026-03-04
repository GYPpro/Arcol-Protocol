class AppConfig {
  static const String appName = 'Arcol Protocol';
  static const String appVersion = '1.0.0';
  
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1';
  
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration pollInterval = Duration(seconds: 30);
}
