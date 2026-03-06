import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:board_app/core/models/auth_response.dart';
import 'package:board_app/core/models/user.dart';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _hasOnboardedKey = 'has_onboarded';
  static const String _userDataKey = 'user_data';

  final SharedPreferences _prefs;

  TokenStorageService(this._prefs);

  /// Save tokens to storage
  Future<void> saveTokens(AuthTokens tokens) async {
    await _prefs.setString(_accessTokenKey, tokens.accessToken);
    await _prefs.setString(_refreshTokenKey, tokens.refreshToken);
  }

  /// Get stored access token
  String? getAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  /// Get stored refresh token
  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  /// Get stored tokens as AuthTokens object
  AuthTokens? getTokens() {
    final accessToken = getAccessToken();
    final refreshToken = getRefreshToken();

    if (accessToken != null && refreshToken != null) {
      return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
    }
    return null;
  }

  /// Save user info
  Future<void> saveUserInfo({
    required int userId,
    required String email,
  }) async {
    await _prefs.setInt(_userIdKey, userId);
    await _prefs.setString(_userEmailKey, email);
  }

  /// Get stored user ID
  int? getUserId() {
    return _prefs.getInt(_userIdKey);
  }

  /// Get stored user email
  String? getUserEmail() {
    return _prefs.getString(_userEmailKey);
  }

  /// Check if user is logged in (has valid tokens)
  bool get isLoggedIn {
    final accessToken = getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Mark onboarding as completed
  Future<void> setHasOnboarded(bool value) async {
    await _prefs.setBool(_hasOnboardedKey, value);
  }

  /// Check if user has completed onboarding
  bool get hasOnboarded {
    return _prefs.getBool(_hasOnboardedKey) ?? false;
  }

  /// Save user data to storage
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(_userDataKey, userJson);
  }

  /// Get stored user data
  User? getUser() {
    final userJson = _prefs.getString(_userDataKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Clear all stored auth data
  Future<void> clearAll() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
    await _prefs.remove(_userDataKey);
    // Note: We don't clear onboarding status on logout
  }
}
