import 'package:board_app/core/models/auth_response.dart';
import 'package:board_app/core/models/user.dart';

class AuthRepository {
  AuthRepository({dynamic apiClient});

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'admin@boardapp.com' && password == 'password123') {
      return AuthResponse(
        success: true,
        message: 'Login successful',
        user: User(
          id: 1,
          name: 'John Doe',
          email: email,
          phone: '+1234567890',
          walletBalance: 0.0,
        ),
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

    return AuthResponse(
      success: true,
      message: 'Registration successful',
      user: User(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        name: name,
        email: email,
        phone: '',
        walletBalance: 0.0,
      ),
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
      user: User(
        id: 1,
        name: 'John Doe',
        email: 'admin@boardapp.com',
        phone: '+1234567890',
        walletBalance: 0.0,
      ),
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
    return AuthResponse(
      success: true,
      message: 'Profile updated',
      user: User(
        id: 1,
        name: name,
        email: 'admin@boardapp.com',
        phone: phone,
        walletBalance: 0.0,
      ),
    );
  }

  Future<AuthResponse> deleteAccount() async {
    await Future.delayed(const Duration(seconds: 1));
    return AuthResponse(success: true, message: 'Account deleted');
  }

  void logout() {}
}
