/// ApiClient Placeholder
///
/// Architectural Boundary:
/// All heavy business logic (LLM integration, BMR/Nutrition calculations,
/// workout plan generation, and authentication verification) is handled
/// by a separate Python FastAPI backend.
///
/// This client will handle standard HTTP communication with FastAPI endpoints
/// using JWT bearer tokens.
class ApiClient {
  final String baseUrl;
  String? _jwtToken;

  ApiClient({this.baseUrl = 'http://localhost:8000'});

  /// Set the authenticated user's JWT token
  void setToken(String token) {
    _jwtToken = token;
  }

  /// Check whether the user is currently authenticated
  bool get isAuthenticated => _jwtToken != null;

  // Placeholder for future endpoints connecting to FastAPI
}

