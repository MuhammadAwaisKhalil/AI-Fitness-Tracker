/// Central API configuration.
/// 
/// During development, point to your local FastAPI server.
/// In production, replace with your deployed backend URL.
class ApiConfig {
  // For Android emulator use 10.0.2.2, for physical device use your PC's local IP
  // For iOS simulator use localhost
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // Auth endpoints
  static const String signupUrl = '$baseUrl/user/signup';
  static const String loginUrl = '$baseUrl/user/login';
  static const String googleLoginUrl = '$baseUrl/user/google-login';
  static const String profileUrl = '$baseUrl/user/me';
}
