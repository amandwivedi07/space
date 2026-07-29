import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/push_service.dart';
import '../../../../core/services/social_auth_service.dart';
import '../../../../core/utils/result.dart';
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
  final bool onboarded; // a live backend session exists
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
    // The API client clears tokens when a refresh is REJECTED; mirror that in
    // state so the router drops the user back to sign-in instead of leaving
    // them on a home screen where every request fails.
    var alive = true;
    ref.onDispose(() => alive = false);
    ref.read(apiClientProvider).onSessionExpired = () {
      if (!alive) return;
      state = const AuthState(loading: false, error: 'Session expired');
    };
    _restore();
    return const AuthState();
  }

  /// Registering the device is what makes a CLOSED app reachable.
  Future<void> _registerPush() async {
    final push = ref.read(pushServiceProvider);
    if (!push.available) await push.initialize();
    await push.registerWithBackend();
  }

  Future<void> _restore() async {
    final hasSession = await _repo.hasSession();
    final user = hasSession ? await _repo.currentUser() : null;
    if (user != null) unawaited(_registerPush());
    state = state.copyWith(
      user: user,
      onboarded: hasSession && user != null,
      loading: false,
    );
  }

  /// Adopts a session result into state; returns true on success.
  bool _adopt(Result<UserProfile> result) => result.when(
        success: (user) {
          state = state.copyWith(
              user: user, onboarded: true, saving: false, loading: false);
          unawaited(_registerPush());
          return true;
        },
        failure: (message) {
          state = state.copyWith(saving: false, error: message);
          return false;
        },
      );

  /// Create an account on Space Talk and adopt the session.
  Future<bool> completeOnboarding({
    required String email,
    required String password,
    required String name,
    required String handle,
    required String note,
    required String paletteId,
    String? photoPath,
  }) async {
    state = state.copyWith(saving: true);
    return _adopt(await _repo.register(
      email: email,
      password: password,
      profile: UserProfile(
        id: '',
        name: name.trim(),
        handle: handle.trim().replaceFirst(RegExp('^@'), ''),
        note: note.trim(),
        paletteId: paletteId,
        photoPath: photoPath,
      ),
    ));
  }

  /// Returning-user sign-in (email + password; kept for tests/tools).
  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(saving: true);
    return _adopt(await _repo.signIn(email: email, password: password));
  }

  /// Sign in with Apple or Google — the app's only front door.
  Future<bool> signInWithFirebase(String idToken) async {
    state = state.copyWith(saving: true);
    return _adopt(await _repo.signInWithFirebase(idToken));
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

  Future<void> signOut() async {
    await ref.read(pushServiceProvider).unregisterFromBackend();
    await ref.read(socialAuthProvider).signOut();
    await _repo.signOut();
    state = const AuthState(loading: false);
  }

  /// Permanently deletes the account (App Store requirement).
  Future<Result<void>> deleteAccount() async {
    state = state.copyWith(saving: true);
    await ref.read(pushServiceProvider).unregisterFromBackend();
    await ref.read(socialAuthProvider).signOut();
    final result = await _repo.deleteAccount();
    result.when(
      success: (_) => state = const AuthState(loading: false),
      failure: (message) => state = state.copyWith(saving: false, error: message),
    );
    return result;
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
