import 'user.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'accessToken': accessToken, 'refreshToken': refreshToken};
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final AuthTokens? tokens;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.tokens,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    User? user;
    if (json['data'] != null && json['data']['user'] != null) {
      user = User.fromJson(json['data']['user'] as Map<String, dynamic>);
    }

    AuthTokens? tokens;
    if (json['tokens'] != null) {
      tokens = AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>);
    }

    return AuthResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      user: user,
      tokens: tokens,
    );
  }
}

class OtpResponse {
  final bool success;
  final String message;

  OtpResponse({required this.success, required this.message});

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
    );
  }
}
