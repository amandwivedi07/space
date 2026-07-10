import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_profile.dart';

/// Auth contract. Swap [MockAuthRepository] for an API-backed implementation
/// by overriding [authRepositoryProvider] — nothing else changes.
abstract class AuthRepository {
  Future<UserProfile?> currentUser();
  Future<bool> isOnboarded();
  Future<Result<UserProfile>> completeOnboarding(UserProfile profile);
  Future<Result<UserProfile>> updateProfile(UserProfile profile);
  Future<void> signOut();
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._local);

  final AuthLocalDataSource _local;

  @override
  Future<UserProfile?> currentUser() => _local.readProfile();

  @override
  Future<bool> isOnboarded() => _local.isOnboarded();

  @override
  Future<Result<UserProfile>> completeOnboarding(UserProfile profile) async {
    // API later: POST /auth/register → session token + profile.
    await _local.writeProfile(profile);
    await _local.setOnboarded(true);
    return Success(profile);
  }

  @override
  Future<Result<UserProfile>> updateProfile(UserProfile profile) async {
    // API later: PATCH /me.
    await _local.writeProfile(profile);
    return Success(profile);
  }

  @override
  Future<void> signOut() => _local.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(
    AuthLocalDataSource(ref.watch(localStorageProvider)),
  ),
);
