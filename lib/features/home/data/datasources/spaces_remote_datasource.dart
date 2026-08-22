import '../../../../core/network/api_client.dart';

/// Raw calls to the Space Talk spaces API.
class SpacesRemoteDataSource {
  SpacesRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> listSpaces() async {
    final data = await _client.get('/spaces') as List<dynamic>? ?? const [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Opens a direct space as a pending request to [userId].
  Future<Map<String, dynamic>> createDirect(String userId) async =>
      await _client.post('/spaces', body: {
        'type': 'direct',
        'member_id': userId,
      }) as Map<String, dynamic>;

  Future<Map<String, dynamic>> createCircle(
          String name, List<String> memberUserIds) async =>
      await _client.post('/spaces', body: {
        'type': 'circle',
        'name': name,
        'member_ids': memberUserIds,
      }) as Map<String, dynamic>;

  Future<void> markSeen(String spaceId) =>
      _client.post('/spaces/$spaceId/seen');

  Future<void> leave(String spaceId) => _client.post('/spaces/$spaceId/leave');

  /// Rename a circle. Any member may; the server decides.
  Future<void> rename(String spaceId, String name) =>
      _client.patch('/spaces/$spaceId', body: {'name': name});

  /// Answer an invitation. Declining discards the space for both people.
  Future<void> acceptRequest(String spaceId) =>
      _client.post('/spaces/$spaceId/accept');

  Future<void> declineRequest(String spaceId) =>
      _client.post('/spaces/$spaceId/decline');

  /// GET /directory/search?q= → [{id, name, palette_id}] — name, or exact email.
  Future<List<dynamic>> searchDirectory(String query) async =>
      await _client.get('/directory/search', query: {'q': query})
          as List<dynamic>;
}
