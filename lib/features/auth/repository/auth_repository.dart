import 'package:board_app/core/models/auth_response.dart';
import 'package:board_app/core/models/user.dart';

class AuthRepository {
  AuthRepository({dynamic apiClient});

  // Static mock user to persist data across app sessions for simulation
  static User? _mockUser;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'admin@boardapp.com' && password == 'password123') {
      _mockUser = User(
        id: 1,
        name: 'John Doe',
        email: email,
        phone: '+1234567890',
        walletBalance: 0.0,
      );
      return AuthResponse(
        success: true,
        message: 'Login successful',
        user: _mockUser,
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

    _mockUser = User(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      name: name,
      email: email,
      phone: '',
      walletBalance: 0.0,
    );

    return AuthResponse(
      success: true,
      message: 'Registration successful',
      user: _mockUser,
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
      user:
          _mockUser ??
          User(
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
    if (_mockUser != null) {
      _mockUser = User(
        id: _mockUser!.id,
        name: name,
        email: _mockUser!.email,
        phone: phone,
        walletBalance: _mockUser!.walletBalance,
      );
    }
    return AuthResponse(
      success: true,
      message: 'Profile updated',
      user: _mockUser,
    );
  }

  Future<AuthResponse> deleteAccount() async {
    await Future.delayed(const Duration(seconds: 1));
    _mockUser = null;
    return AuthResponse(success: true, message: 'Account deleted');
  }

  void logout() {
    _mockUser = null;
  }

  void setMockUser(User user) {
    _mockUser = user;
  }
}
