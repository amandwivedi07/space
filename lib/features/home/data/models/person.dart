import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/presence.dart';

/// A person you share a space with — one drifting bubble on the cluster.
class Person {
  const Person({
    required this.id,
    required this.name,
    this.paletteId = 'ember',
    this.sizeKey = 'md',
    this.unread = 0,
    this.presence = Presence.away,
    this.x = 50,
    this.y = 50,
    required this.lastActivity,
    this.phone,
    this.pending = false,
  });

  final String id;
  final String name;
  final String paletteId;
  final String sizeKey; // sm | md | lg | xl — closeness, not importance
  final int unread;
  final Presence presence;
  final double x; // 0–100 cluster coordinates
  final double y;
  final DateTime lastActivity;
  final String? phone;
  final bool pending; // invited, not yet on Space

  double get bubbleSize => switch (sizeKey) {
        'sm' => AppConstants.bubbleSm,
        'lg' => AppConstants.bubbleLg,
        'xl' => AppConstants.bubbleXl,
        _ => AppConstants.bubbleMd,
      };

  Person copyWith({int? unread, Presence? presence, DateTime? lastActivity}) =>
      Person(
        id: id,
        name: name,
        paletteId: paletteId,
        sizeKey: sizeKey,
        unread: unread ?? this.unread,
        presence: presence ?? this.presence,
        x: x,
        y: y,
        lastActivity: lastActivity ?? this.lastActivity,
        phone: phone,
        pending: pending,
      );

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        paletteId: json['paletteId'] as String? ?? 'ember',
        sizeKey: json['sizeKey'] as String? ?? 'md',
        unread: (json['unread'] as num?)?.toInt() ?? 0,
        presence: Presence.fromId(json['presence'] as String?),
        x: (json['x'] as num?)?.toDouble() ?? 50,
        y: (json['y'] as num?)?.toDouble() ?? 50,
        lastActivity: DateTime.tryParse(json['lastActivity'] as String? ?? '') ??
            DateTime.now(),
        phone: json['phone'] as String?,
        pending: json['pending'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'paletteId': paletteId,
        'sizeKey': sizeKey,
        'unread': unread,
        'presence': presence.name,
        'x': x,
        'y': y,
        'lastActivity': lastActivity.toIso8601String(),
        'phone': phone,
        'pending': pending,
      };
}
