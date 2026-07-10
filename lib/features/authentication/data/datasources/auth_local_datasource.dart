import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/user_profile.dart';

/// Device-local persistence of the session/profile.
/// A future AuthRemoteDataSource implements the same surface against the API.
class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  final LocalStorageService _storage;

  Future<UserProfile?> readProfile() async {
    final json = await _storage.getJson(AppConstants.profileKey);
    return json == null ? null : UserProfile.fromJson(json);
  }

  Future<void> writeProfile(UserProfile profile) =>
      _storage.setJson(AppConstants.profileKey, profile.toJson());

  Future<bool> isOnboarded() async =>
      await _storage.getBool(AppConstants.onboardedKey) ?? false;

  Future<void> setOnboarded(bool value) =>
      _storage.setBool(AppConstants.onboardedKey, value);

  Future<void> clear() async {
    await _storage.remove(AppConstants.profileKey);
    await _storage.remove(AppConstants.onboardedKey);
  }
}
