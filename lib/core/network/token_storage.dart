import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_service.dart';

/// Persists the JWT pair. Rotation-aware: every refresh overwrites both.
class TokenStorage {
  TokenStorage(this._storage);

  final LocalStorageService _storage;
  static const _key = 'space.tokens.v1';

  String? _access;
  String? _refresh;

  String? get accessToken => _access;
  String? get refreshToken => _refresh;
  bool get hasSession => _refresh != null;

  Future<void> restore() async {
    final json = await _storage.getJson(_key);
    _access = json?['access'] as String?;
    _refresh = json?['refresh'] as String?;
  }

  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
    await _storage.setJson(_key, {'access': access, 'refresh': refresh});
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await _storage.remove(_key);
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(localStorageProvider)),
);
