import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/utils/result.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_profile.dart';

/// Auth contract. The app is wired to [ApiAuthRepository] (Space Talk backend);
/// [MockAuthRepository] remains for offline demos/tests via provider override.
abstract class AuthRepository {
  Future<UserProfile?> currentUser();
  Future<bool> hasSession();
  Future<Result<UserProfile>> register({
    required String email,
    required String password,
    required UserProfile profile,
  });
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  });

  /// Exchange a Firebase ID token (Apple/Google) for a Space session.
  Future<Result<UserProfile>> signInWithFirebase(String idToken);
  Future<Result<UserProfile>> updateProfile(UserProfile profile);
  Future<Result<void>> forgotPassword(String email);
  Future<Result<void>> resetPassword(String token, String password);
  Future<Result<void>> deleteAccount();
  Future<void> signOut();
}

/// Backend-backed implementation: email+password auth, JWT pair persisted,
/// profile merged from GET /auth/me + device-local flourishes.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._remote, this._tokens, this._local);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;
  final AuthLocalDataSource _local;

  bool _restored = false;

  Future<void> _ensureRestored() async {
    if (_restored) return;
    await _tokens.restore();
    _restored = true;
  }

  @override
  Future<bool> hasSession() async {
    await _ensureRestored();
    return _tokens.hasSession;
  }

  @override
  Future<UserProfile?> currentUser() async {
    await _ensureRestored();
    if (!_tokens.hasSession) return null;
    final cached = await _local.readProfile();
    try {
      final server = await _remote.me();
      final merged =
          (cached ?? const UserProfile(id: '', name: '')).mergeServer(server);
      await _local.writeProfile(merged);
      return merged;
    } on ApiException catch (e) {
      if (e.isUnauthorized) return null; // refresh failed → session dead
      Log.w('me() unreachable, using cached profile: $e');
      return cached; // offline: keep the last known self
    }
  }

  Future<UserProfile> _adopt(
      Map<String, dynamic> payload, UserProfile localExtras) async {
    final tokens = payload['tokens'] as Map<String, dynamic>;
    await _tokens.save(
      access: tokens['access_token'] as String,
      refresh: tokens['refresh_token'] as String,
    );
    final profile =
        localExtras.mergeServer(payload['user'] as Map<String, dynamic>);
    await _local.writeProfile(profile);
    await _local.setOnboarded(true);
    return profile;
  }

  @override
  Future<Result<UserProfile>> register({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    try {
      final payload = await _remote.register(
          email: email, password: password, name: profile.name);
      return Success(await _adopt(payload, profile));
    } on ApiException catch (e) {
      return Failure(
          e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message);
    }
  }

  @override
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final payload = await _remote.login(email: email, password: password);
      final extras =
          await _local.readProfile() ?? const UserProfile(id: '', name: '');
      return Success(await _adopt(payload, extras));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<UserProfile>> signInWithFirebase(String idToken) async {
    try {
      final payload = await _remote.firebaseLogin(idToken);
      final extras =
          await _local.readProfile() ?? const UserProfile(id: '', name: '');
      return Success(await _adopt(payload, extras));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<UserProfile>> updateProfile(UserProfile profile) async {
    try {
      await _remote.updateMe(name: profile.name, paletteId: profile.paletteId);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Failure(e.message);
      Log.w('updateMe failed, keeping local copy: $e'); // offline-tolerant
    }
    await _local.writeProfile(profile);
    return Success(profile);
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(email);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<void>> resetPassword(String token, String password) async {
    try {
      await _remote.resetPassword(token, password);
      return const Success(null);
    } on ApiException catch (e) {
      return Failure(e.fieldErrors.isNotEmpty
          ? e.fieldErrors.values.first
          : e.message);
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _remote.deleteAccount();
    } on ApiException catch (e) {
      return Failure(e.message);
    }
    // Local wipe happens regardless — the server side is already gone.
    await _tokens.clear();
    await _local.clear();
    return const Success(null);
  }

  @override
  Future<void> signOut() async {
    await _ensureRestored();
    final refresh = _tokens.refreshToken;
    if (refresh != null) {
      try {
        await _remote.logout(refresh);
      } on ApiException catch (e) {
        Log.w('logout call failed (revoking locally anyway): $e');
      }
    }
    await _tokens.clear();
    await _local.clear();
  }
}

/// Device-only implementation — used in tests/offline demos.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._local);

  final AuthLocalDataSource _local;

  @override
  Future<UserProfile?> currentUser() => _local.readProfile();

  @override
  Future<bool> hasSession() => _local.isOnboarded();

  @override
  Future<Result<UserProfile>> register({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    final stored = profile.copyWith(email: email);
    await _local.writeProfile(stored);
    await _local.setOnboarded(true);
    return Success(stored);
  }

  @override
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    final profile = await _local.readProfile();
    if (profile == null) return const Failure('No account on this device yet');
    return Success(profile);
  }

  @override
  Future<Result<UserProfile>> signInWithFirebase(String idToken) async {
    const profile = UserProfile(id: 'me', name: 'You');
    await _local.writeProfile(profile);
    await _local.setOnboarded(true);
    return const Success(profile);
  }

  @override
  Future<Result<UserProfile>> updateProfile(UserProfile profile) async {
    await _local.writeProfile(profile);
    return Success(profile);
  }

  @override
  Future<Result<void>> forgotPassword(String email) async => const Success(null);

  @override
  Future<Result<void>> resetPassword(String token, String password) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteAccount() async {
    await _local.clear();
    return const Success(null);
  }

  @override
  Future<void> signOut() => _local.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(
    AuthRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(tokenStorageProvider),
    AuthLocalDataSource(ref.watch(localStorageProvider)),
  ),
);
