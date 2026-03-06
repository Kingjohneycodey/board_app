import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:board_app/core/models/auth_response.dart';
import 'package:board_app/core/models/user.dart';

class AuthRepository {
  AuthRepository({dynamic apiClient});

  static const String _mockUsersKey = 'mock_users_db';

  // Simulator for a backend database
  static Map<String, User> _mockUsers = {
    'admin@boardapp.com': User(
      id: 1,
      name: 'John Doe',
      email: 'admin@boardapp.com',
      walletBalance: 0.0,
    ),
  };

  // Current logged in user (in-memory mock)
  static User? _mockCurrentUser;

  /// Call this at app startup to restore the "database"
  static void init(SharedPreferences prefs) {
    final data = prefs.getString(_mockUsersKey);
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(data);
        decoded.forEach((key, value) {
          _mockUsers[key] = User.fromJson(value);
        });
      } catch (_) {}
    }
  }

  static Future<void> _persistDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> export = {};
    _mockUsers.forEach((key, value) {
      export[key] = value.toJson();
    });
    await prefs.setString(_mockUsersKey, jsonEncode(export));
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // In a mock, we accept any password for registered users
    final user = _mockUsers[email];
    if (user != null) {
      _mockCurrentUser = user;
      return AuthResponse(
        success: true,
        message: 'Login successful',
        user: user,
        tokens: AuthTokens(
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
        ),
      );
    }

    return AuthResponse(success: false, message: 'Invalid email or password');
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_mockUsers.containsKey(email)) {
      return AuthResponse(success: false, message: 'Email already registered');
    }

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      name: name,
      email: email,
      phone: '',
      walletBalance: 0.0,
    );

    // Save to our "database"
    _mockUsers[email] = newUser;
    _mockCurrentUser = newUser;
    await _persistDatabase();

    return AuthResponse(
      success: true,
      message: 'Registration successful',
      user: newUser,
      tokens: AuthTokens(
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
      ),
    );
  }

  Future<AuthResponse> refreshAccessToken(String refreshToken) async {
    return AuthResponse(
      success: true,
      message: 'Token refreshed',
      tokens: AuthTokens(
        accessToken: 'mock_new_access_token',
        refreshToken: refreshToken,
      ),
    );
  }

  Future<AuthResponse> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return AuthResponse(
      success: true,
      message: 'Profile fetched',
      user: _mockCurrentUser ?? _mockUsers['admin@boardapp.com']!,
    );
  }

  Future<AuthResponse> updateProfile({
    required String name,
    required String phone,
    String? dateOfBirth,
    String? language,
    dynamic photo,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_mockCurrentUser != null) {
      final updatedUser = User(
        id: _mockCurrentUser!.id,
        name: name,
        email: _mockCurrentUser!.email,
        phone: phone,
        walletBalance: _mockCurrentUser!.walletBalance,
      );
      _mockCurrentUser = updatedUser;
      _mockUsers[updatedUser.email] = updatedUser;
      await _persistDatabase();
    }
    return AuthResponse(
      success: true,
      message: 'Profile updated',
      user: _mockCurrentUser,
    );
  }

  Future<AuthResponse> deleteAccount() async {
    await Future.delayed(const Duration(seconds: 1));
    if (_mockCurrentUser != null) {
      _mockUsers.remove(_mockCurrentUser!.email);
      _mockCurrentUser = null;
      await _persistDatabase();
    }
    return AuthResponse(success: true, message: 'Account deleted');
  }

  void logout() {
    _mockCurrentUser = null;
  }

  void setMockUser(User user) {
    _mockCurrentUser = user;
    _mockUsers[user.email] = user;
    _persistDatabase();
  }
}
