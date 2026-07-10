import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/presence.dart';

/// A small circle — a group space shared by a few people.
class CircleSpace {
  const CircleSpace({
    required this.id,
    required this.name,
    required this.memberIds,
    this.unread = 0,
    this.presence = Presence.away,
    this.sizeKey = 'lg',
    this.x = 50,
    this.y = 50,
    required this.lastActivity,
  });

  final String id;
  final String name;
  final List<String> memberIds;
  final int unread;
  final Presence presence;
  final String sizeKey;
  final double x;
  final double y;
  final DateTime lastActivity;

  double get bubbleSize => switch (sizeKey) {
        'sm' => AppConstants.bubbleSm,
        'md' => AppConstants.bubbleMd,
        'xl' => AppConstants.bubbleXl,
        _ => AppConstants.bubbleLg,
      };

  CircleSpace copyWith({int? unread, Presence? presence}) => CircleSpace(
        id: id,
        name: name,
        memberIds: memberIds,
        unread: unread ?? this.unread,
        presence: presence ?? this.presence,
        sizeKey: sizeKey,
        x: x,
        y: y,
        lastActivity: lastActivity,
      );

  factory CircleSpace.fromJson(Map<String, dynamic> json) => CircleSpace(
        id: json['id'] as String,
        name: json['name'] as String,
        memberIds: List<String>.from(json['memberIds'] as List? ?? const []),
        unread: (json['unread'] as num?)?.toInt() ?? 0,
        presence: Presence.fromId(json['presence'] as String?),
        sizeKey: json['sizeKey'] as String? ?? 'lg',
        x: (json['x'] as num?)?.toDouble() ?? 50,
        y: (json['y'] as num?)?.toDouble() ?? 50,
        lastActivity: DateTime.tryParse(json['lastActivity'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'memberIds': memberIds,
        'unread': unread,
        'presence': presence.name,
        'sizeKey': sizeKey,
        'x': x,
        'y': y,
        'lastActivity': lastActivity.toIso8601String(),
      };
}
