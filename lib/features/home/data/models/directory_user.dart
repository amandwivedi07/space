/// Someone found in the people directory. Deliberately thin — the directory
/// never exposes email addresses, only enough to recognise a person.
class DirectoryUser {
  const DirectoryUser({
    required this.id,
    required this.name,
    required this.paletteId,
    this.handle = '',
    this.avatarUrl = '',
  });

  factory DirectoryUser.fromJson(Map<String, dynamic> json) => DirectoryUser(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Someone',
        paletteId: json['palette_id'] as String? ?? 'ember',
        handle: json['handle'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
      );

  final String id;
  final String name;
  final String paletteId;

  /// Stable @handle from their email — the only way to tell two people with
  /// the same display name apart.
  final String handle;

  /// Google profile photo. Apple never gives one, so this is often empty.
  final String avatarUrl;
}
