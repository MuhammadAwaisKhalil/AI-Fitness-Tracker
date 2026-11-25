import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure JWT token storage using platform keychain/keystore.
class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'auth_jwt_token';
  static const _emailKey = 'auth_user_email';
  static const _providerKey = 'auth_provider';

  /// Save auth session data securely.
  static Future<void> saveSession({
    required String token,
    required String email,
    required String provider,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _providerKey, value: provider);
  }

  /// Read the stored JWT token.
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Read the stored email.
  static Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  /// Read the stored auth provider.
  static Future<String?> getProvider() async {
    return await _storage.read(key: _providerKey);
  }

  /// Check if a valid session exists.
  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored auth data (logout).
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
