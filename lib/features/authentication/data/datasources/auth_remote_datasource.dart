import '../../../../core/network/api_client.dart';

/// Raw calls to the Space Talk auth API. Returns decoded `data` payloads;
/// the repository turns them into domain models.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  /// POST /auth/register → {user, tokens}
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async =>
      await _client.post('/auth/register', body: {
        'email': email,
        'password': password,
        'name': name,
      }) as Map<String, dynamic>;

  /// POST /auth/login → {user, tokens}
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async =>
      await _client.post('/auth/login', body: {
        'email': email,
        'password': password,
      }) as Map<String, dynamic>;

  /// POST /auth/firebase — Apple/Google ID token → Space session.
  Future<Map<String, dynamic>> firebaseLogin(String idToken) async =>
      await _client.post('/auth/firebase', body: {'id_token': idToken})
          as Map<String, dynamic>;

  /// GET /auth/me → user
  Future<Map<String, dynamic>> me() async =>
      await _client.get('/auth/me') as Map<String, dynamic>;

  /// PATCH /auth/me → user
  Future<Map<String, dynamic>> updateMe(
          {String? name, String? avatarUrl, String? paletteId}) async =>
      await _client.patch('/auth/me', body: {
        'name': ?name,
        'avatar_url': ?avatarUrl,
        'palette_id': ?paletteId,
      }) as Map<String, dynamic>;

  /// POST /auth/logout — revokes the refresh token server-side.
  Future<void> logout(String refreshToken) =>
      _client.post('/auth/logout', body: {'refresh_token': refreshToken});

  Future<void> forgotPassword(String email) =>
      _client.post('/auth/forgot-password', body: {'email': email});

  Future<void> resetPassword(String token, String password) => _client
      .post('/auth/reset-password', body: {'token': token, 'password': password});

  /// DELETE /auth/account — irreversible.
  Future<void> deleteAccount() => _client.delete('/auth/account');
}
