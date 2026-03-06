import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/core/models/user.dart';
import 'package:board_app/core/services/token_storage_service.dart';
import 'package:board_app/features/auth/providers/auth_provider.dart';
import 'package:board_app/features/auth/repository/auth_repository.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileNotifier extends Notifier<User?> {
  late final TokenStorageService _tokenStorage;
  late final AuthRepository _authRepository;

  @override
  User? build() {
    _tokenStorage = ref.watch(tokenStorageProvider);
    _authRepository = ref.watch(authRepositoryProvider);

    // Load profile from local storage first
    final cachedUser = _tokenStorage.getUser();

    // Schedule async fetch for after initialization
    if (cachedUser != null) {
      _authRepository.setMockUser(cachedUser);
      Future.microtask(() => fetchProfile());
    }

    return cachedUser;
  }

  /// Fetch profile from API and update local storage
  Future<void> fetchProfile() async {
    try {
      final response = await _authRepository.getProfile();
      if (response.success && response.user != null) {
        state = response.user;
        // Save to local storage
        await _tokenStorage.saveUser(response.user!);
      }
    } catch (_) {
      // Silently fail - we already have cached data
    }
  }

  /// Refresh profile (can be called manually)
  Future<void> refresh() async {
    await fetchProfile();
  }

  /// Clear profile (on logout)
  void clear() {
    state = null;
  }

  /// Edit profile from EditAccountScreen
  Future<void> editProfile({
    required String name,
    required String phone,
    String? dateOfBirth,
    String? language,
    XFile? photo,
  }) async {
    final response = await _authRepository.updateProfile(
      name: name,
      phone: phone,
      dateOfBirth: dateOfBirth,
      language: language,
      photo: photo,
    );
    if (response.success && response.user != null) {
      state = response.user;
      await _tokenStorage.saveUser(response.user!);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final response = await _authRepository.deleteAccount();
    if (response.success) {
      clear();
      await _tokenStorage.clearAll();
      _authRepository.logout();
    } else {
      throw Exception(response.message);
    }
  }
}

// User Profile Provider
final userProfileProvider = NotifierProvider<UserProfileNotifier, User?>(() {
  return UserProfileNotifier();
});
