import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/id_generator.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

/// Auth/session state consumed by splash, onboarding and profile.
class AuthState {
  const AuthState({
    this.user,
    this.onboarded = false,
    this.loading = true,
    this.saving = false,
    this.error,
  });

  final UserProfile? user;
  final bool onboarded;
  final bool loading;
  final bool saving;
  final String? error;

  AuthState copyWith({
    UserProfile? user,
    bool? onboarded,
    bool? loading,
    bool? saving,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        onboarded: onboarded ?? this.onboarded,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        error: error,
      );
}

class AuthViewModel extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    _restore();
    return const AuthState();
  }

  Future<void> _restore() async {
    final user = await _repo.currentUser();
    final onboarded = await _repo.isOnboarded();
    state = state.copyWith(user: user, onboarded: onboarded, loading: false);
  }

  Future<bool> completeOnboarding({
    required String name,
    required String handle,
    required String note,
    required String paletteId,
    String? photoPath,
  }) async {
    state = state.copyWith(saving: true);
    final profile = UserProfile(
      id: IdGenerator.next('me'),
      name: name.trim(),
      handle: handle.trim().replaceFirst(RegExp('^@'), ''),
      note: note.trim(),
      paletteId: paletteId,
      photoPath: photoPath,
    );
    final result = await _repo.completeOnboarding(profile);
    return result.when(
      success: (user) {
        state = state.copyWith(
            user: user, onboarded: true, saving: false, loading: false);
        return true;
      },
      failure: (message) {
        state = state.copyWith(saving: false, error: message);
        return false;
      },
    );
  }

  Future<bool> updateProfile(UserProfile profile) async {
    state = state.copyWith(saving: true);
    final result = await _repo.updateProfile(profile);
    return result.when(
      success: (user) {
        state = state.copyWith(user: user, saving: false);
        return true;
      },
      failure: (message) {
        state = state.copyWith(saving: false, error: message);
        return false;
      },
    );
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
