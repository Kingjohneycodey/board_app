import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:board_app/core/services/token_storage_service.dart';
import 'package:board_app/features/auth/repository/auth_repository.dart';
import 'package:board_app/core/models/user.dart';
import 'package:board_app/core/models/auth_response.dart';
import 'package:board_app/features/profile/providers/profile_provider.dart';

// SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

// Token Storage Service Provider
final tokenStorageProvider = Provider<TokenStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TokenStorageService(prefs);
});

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth State Enum
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

// Auth State Class
class AuthState {
  final AuthStatus status;
  final User? user;
  final AuthTokens? tokens;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.tokens,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    AuthTokens? tokens,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      tokens: tokens ?? this.tokens,
      errorMessage: errorMessage,
    );
  }
}

// Auth Notifier using new Riverpod 3.x API
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;
  late final TokenStorageService _tokenStorage;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _tokenStorage = ref.watch(tokenStorageProvider);

    // Initialize auth state from stored tokens and return it directly
    final tokens = _tokenStorage.getTokens();
    final user = _tokenStorage.getUser();
    if (tokens != null) {
      if (user != null) {
        _repository.setMockUser(user);
      }
      return AuthState(
        status: AuthStatus.authenticated,
        tokens: tokens,
        user: user,
      );
    } else {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

      final response = await _repository.login(
        email: email,
        password: password,
      );

      return _handleAuthResponse(response);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Register with name, email, and password
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

      final response = await _repository.register(
        name: name,
        email: email,
        password: password,
      );

      return _handleAuthResponse(response);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> _handleAuthResponse(AuthResponse response) async {
    if (response.success && response.tokens != null) {
      // Save tokens to storage
      await _tokenStorage.saveTokens(response.tokens!);

      // Save user info if available
      if (response.user != null) {
        await _tokenStorage.saveUserInfo(
          userId: response.user!.id,
          email: response.user!.email,
        );
        // Save full user data
        await _tokenStorage.saveUser(response.user!);
      }

      // Mark onboarding as completed since they are now authenticated
      await _tokenStorage.setHasOnboarded(true);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        tokens: response.tokens,
      );

      // Fetch profile immediately after login/register
      await ref.read(userProfileProvider.notifier).fetchProfile();

      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: response.message,
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _tokenStorage.clearAll();
    _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
    // Clear profile data
    ref.read(userProfileProvider.notifier).clear();
  }

  /// Refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await logout();
        return false;
      }

      final response = await _repository.refreshAccessToken(refreshToken);

      if (response.success && response.tokens != null) {
        await _tokenStorage.saveTokens(response.tokens!);
        state = state.copyWith(tokens: response.tokens);
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Check if user is logged in
  bool get isLoggedIn => _tokenStorage.isLoggedIn;
}

// Auth Notifier Provider using new Riverpod 3.x API
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// Convenience providers for accessing specific parts of auth state
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider.select((state) => state.user));
});

final authStateProvider = Provider<AuthTokens?>((ref) {
  return ref.watch(authNotifierProvider.select((state) => state.tokens));
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(
    authNotifierProvider.select((state) => state.status == AuthStatus.loading),
  );
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider.select((state) => state.errorMessage));
});
