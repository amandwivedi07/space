/// The signed-in user's identity ("Your quiet self").
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.handle = '',
    this.note = '',
    this.paletteId = 'ember',
    this.photoPath,
  });

  final String id;
  final String name;
  final String handle;
  final String note;
  final String paletteId;
  final String? photoPath;

  UserProfile copyWith({
    String? name,
    String? handle,
    String? note,
    String? paletteId,
    String? photoPath,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        handle: handle ?? this.handle,
        note: note ?? this.note,
        paletteId: paletteId ?? this.paletteId,
        photoPath: photoPath ?? this.photoPath,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? 'me',
        name: json['name'] as String? ?? '',
        handle: json['handle'] as String? ?? '',
        note: json['note'] as String? ?? '',
        paletteId: json['paletteId'] as String? ?? 'ember',
        photoPath: json['photoPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'handle': handle,
        'note': note,
        'paletteId': paletteId,
        'photoPath': photoPath,
      };
}
