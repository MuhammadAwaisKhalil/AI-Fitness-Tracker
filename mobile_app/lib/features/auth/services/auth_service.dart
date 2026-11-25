import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/services/token_storage.dart';

/// Represents the result of an authentication operation.
class AuthResult {
  final bool success;
  final String? token;
  final String? error;
  final String? email;
  final String? authProvider;

  const AuthResult({
    required this.success,
    this.token,
    this.error,
    this.email,
    this.authProvider,
  });
}

/// Real AuthService that communicates with the FastAPI backend.
///
/// Architectural Boundary:
/// All authentication logic (password hashing, JWT signing, Google token
/// verification) is handled exclusively by the Python FastAPI backend.
/// This service is a thin HTTP client that sends credentials and stores
/// the returned JWT securely.
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // ADD THIS LINE: Use the Web Application Client ID from Google Cloud Console.
    serverClientId: '32745464974-aaidebr2vv03mvkch1mgjf0579stbg6a.apps.googleusercontent.com', 
    scopes: ['email', 'profile'],
  );

  String? _currentToken;
  String? _currentEmail;

  bool get isLoggedIn => _currentToken != null;
  String? get currentEmail => _currentEmail;
  String? get token => _currentToken;

  /// Initialize — check for existing session on app start.
  Future<void> init() async {
    final hasSession = await TokenStorage.hasSession();
    if (hasSession) {
      _currentToken = await TokenStorage.getToken();
      _currentEmail = await TokenStorage.getEmail();
    }
  }

  /// POST /user/signup — local account registration
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signupUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _handleSuccessResponse(data);
        return AuthResult(
          success: true,
          token: data['access_token'],
          email: data['email'],
          authProvider: data['auth_provider'],
        );
      } else {
        return AuthResult(
          success: false,
          error: data['detail'] ?? 'Signup failed.',
        );
      }
    } on TimeoutException {
      return const AuthResult(
        success: false,
        error: 'Connection timed out. Check your network.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// POST /user/login — local account login
  /// Uses OAuth2 form format (application/x-www-form-urlencoded)
  Future<AuthResult> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,  // OAuth2 form uses 'username' field
          'password': password,
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _handleSuccessResponse(data);
        return AuthResult(
          success: true,
          token: data['access_token'],
          email: data['email'],
          authProvider: data['auth_provider'],
        );
      } else {
        return AuthResult(
          success: false,
          error: data['detail'] ?? 'Login failed.',
        );
      }
    } on TimeoutException {
      return const AuthResult(
        success: false,
        error: 'Connection timed out. Check your network.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Google Sign-In flow:
  /// 1. Use GoogleSignIn SDK to get the Google ID token on-device
  /// 2. Send the ID token to our backend POST /user/google-login
  /// 3. Backend validates with Google and returns our JWT
  Future<AuthResult> continueWithGoogle() async {
    try {
      // Step 1: Trigger the native Google Sign-In UI
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResult(
          success: false,
          error: 'Google sign-in was cancelled.',
        );
      }

      // Step 2: Get the authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return const AuthResult(
          success: false,
          error: 'Failed to retrieve Google ID token.',
        );
      }

      // Step 3: Send ID token to our backend for verification
      final response = await http.post(
        Uri.parse(ApiConfig.googleLoginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _handleSuccessResponse(data);
        return AuthResult(
          success: true,
          token: data['access_token'],
          email: data['email'],
          authProvider: 'google',
        );
      } else {
        return AuthResult(
          success: false,
          error: data['detail'] ?? 'Google authentication failed.',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Google sign-in error: ${e.toString()}',
      );
    }
  }

  /// Log out — clear stored session and Google sign-in.
  Future<void> logOut() async {
    _currentToken = null;
    _currentEmail = null;
    await TokenStorage.clearSession();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out errors
    }
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────

  Future<void> _handleSuccessResponse(Map<String, dynamic> data) async {
    _currentToken = data['access_token'];
    _currentEmail = data['email'];
    await TokenStorage.saveSession(
      token: data['access_token'],
      email: data['email'],
      provider: data['auth_provider'] ?? 'local',
    );
  }
}
