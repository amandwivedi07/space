import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/presence.dart';

/// Where a direct space sits in the invitation dance.
enum SpaceRequest {
  /// Open — both people agreed, cards can flow.
  none,

  /// They asked; you have to accept or decline.
  incoming,

  /// You asked; nothing can be said until they accept.
  outgoing,
}

/// A person you share a space with — one drifting bubble on the cluster.
class Person {
  const Person({
    required this.id,
    required this.name,
    this.userId = '',
    this.paletteId = 'ember',
    this.sizeKey = 'md',
    this.unread = 0,
    this.presence = Presence.away,
    this.x = 50,
    this.y = 50,
    required this.lastActivity,
    this.phone,
    this.request = SpaceRequest.none,
    this.handle = '',
    this.avatarUrl = '',
  });

  /// With the live backend: id = space id, userId = the other member's user id.
  final String id;
  final String userId;
  final String name;
  final String paletteId;
  final String sizeKey; // sm | md | lg | xl — closeness, not importance
  final int unread;
  final Presence presence;
  final double x; // 0–100 cluster coordinates
  final double y;
  final DateTime lastActivity;
  final String? phone;
  final SpaceRequest request;

  /// @handle from their email, and their Google photo when they have one.
  final String handle;
  final String avatarUrl;

  /// True while this space is an unanswered invitation, either direction.
  bool get awaitingAnswer => request != SpaceRequest.none;

  double get bubbleSize => switch (sizeKey) {
    'sm' => AppConstants.bubbleSm,
    'lg' => AppConstants.bubbleLg,
    'xl' => AppConstants.bubbleXl,
    _ => AppConstants.bubbleMd,
  };

  Person copyWith({int? unread, Presence? presence, DateTime? lastActivity}) =>
      Person(
        request: request,
        handle: handle,
        avatarUrl: avatarUrl,
        userId: userId,
        phone: phone,
        id: id,
        name: name,
        paletteId: paletteId,
        sizeKey: sizeKey,
        unread: unread ?? this.unread,
        presence: presence ?? this.presence,
        x: x,
        y: y,
        lastActivity: lastActivity ?? this.lastActivity,
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
    lastActivity:
        DateTime.tryParse(json['lastActivity'] as String? ?? '') ??
        DateTime.now(),
    phone: json['phone'] as String?,
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
  };
}
