/// The signed-in user's identity ("Your quiet self").
/// id/email/name/handle come from the backend; note/palette/photo are
/// device-local flourishes until the server learns about them.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.email = '',
    this.handle = '',
    this.note = '',
    this.paletteId = 'ember',
    this.photoPath,
    this.avatarUrl = '',
  });

  final String id;
  final String name;
  final String email;
  final String handle;
  final String note;
  final String paletteId;
  final String? photoPath;

  /// The Google photo the identity provider gave us. A locally chosen
  /// [photoPath] takes precedence over it.
  final String avatarUrl;

  UserProfile copyWith({
    String? name,
    String? email,
    String? handle,
    String? note,
    String? paletteId,
    String? photoPath,
    String? avatarUrl,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        handle: handle ?? this.handle,
        note: note ?? this.note,
        paletteId: paletteId ?? this.paletteId,
        photoPath: photoPath ?? this.photoPath,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? 'me',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        handle: json['handle'] as String? ?? '',
        note: json['note'] as String? ?? '',
        paletteId: json['paletteId'] as String? ?? 'ember',
        photoPath: json['photoPath'] as String?,
        avatarUrl: json['avatarUrl'] as String? ?? '',
      );

  /// Merge the backend user payload onto local-only fields.
  UserProfile mergeServer(Map<String, dynamic> server) => UserProfile(
        id: server['id'] as String? ?? id,
        name: server['name'] as String? ?? name,
        email: server['email'] as String? ?? email,
        // Derived from the email server-side, so the server always wins.
        handle: server['handle'] as String? ?? handle,
        note: note,
        paletteId: paletteId,
        photoPath: photoPath,
        avatarUrl: server['avatar_url'] as String? ?? avatarUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'handle': handle,
        'note': note,
        'paletteId': paletteId,
        'photoPath': photoPath,
        'avatarUrl': avatarUrl,
      };
}
