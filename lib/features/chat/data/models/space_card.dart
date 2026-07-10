import '../../../../core/constants/fade_options.dart';

/// What a card holds.
enum CardType { text, photo, video, voice, link, file, aiImage, aiVideo }

/// One ephemeral message card. Fade timers count from [seenAt];
/// kept cards never fade; view-once cards vanish after [consumedAt].
class SpaceCard {
  const SpaceCard({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    this.body = '',
    this.mediaPath,
    this.linkUrl,
    this.durationSec = 0,
    this.fade = FadeOption.m1,
    required this.sentAt,
    this.seenAt,
    this.consumedAt,
    this.kept = false,
    this.aiGenerated = false,
    this.aiSeed = 0,
  });

  final String id;
  final String roomId;
  final String senderId; // 'me' or a person id
  final CardType type;
  final String body;
  final String? mediaPath;
  final String? linkUrl;
  final int durationSec;
  final FadeOption fade;
  final DateTime sentAt;
  final DateTime? seenAt;
  final DateTime? consumedAt; // view-once reveal moment
  final bool kept;
  final bool aiGenerated;
  final int aiSeed; // deterministic gradient for mock AI media

  bool get isMine => senderId == 'me';
  bool get isViewOnce => fade.isViewOnce;
  bool get viewOnceConsumed => isViewOnce && consumedAt != null;

  DateTime? get expiresAt {
    if (kept) return null;
    if (isViewOnce) {
      return consumedAt?.add(const Duration(seconds: 3));
    }
    return seenAt?.add(fade.duration);
  }

  Duration? get remaining {
    final at = expiresAt;
    if (at == null) return null;
    final left = at.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get expired {
    final at = expiresAt;
    return at != null && DateTime.now().isAfter(at);
  }

  SpaceCard copyWith({
    DateTime? seenAt,
    DateTime? consumedAt,
    bool? kept,
  }) =>
      SpaceCard(
        id: id,
        roomId: roomId,
        senderId: senderId,
        type: type,
        body: body,
        mediaPath: mediaPath,
        linkUrl: linkUrl,
        durationSec: durationSec,
        fade: fade,
        sentAt: sentAt,
        seenAt: seenAt ?? this.seenAt,
        consumedAt: consumedAt ?? this.consumedAt,
        kept: kept ?? this.kept,
        aiGenerated: aiGenerated,
        aiSeed: aiSeed,
      );

  factory SpaceCard.fromJson(Map<String, dynamic> json) => SpaceCard(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        senderId: json['senderId'] as String,
        type: CardType.values.firstWhere((t) => t.name == json['type'],
            orElse: () => CardType.text),
        body: json['body'] as String? ?? '',
        mediaPath: json['mediaPath'] as String?,
        linkUrl: json['linkUrl'] as String?,
        durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
        fade: FadeOption.fromId(json['fade'] as String?),
        sentAt: DateTime.parse(json['sentAt'] as String),
        seenAt: DateTime.tryParse(json['seenAt'] as String? ?? ''),
        consumedAt: DateTime.tryParse(json['consumedAt'] as String? ?? ''),
        kept: json['kept'] as bool? ?? false,
        aiGenerated: json['aiGenerated'] as bool? ?? false,
        aiSeed: (json['aiSeed'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'senderId': senderId,
        'type': type.name,
        'body': body,
        'mediaPath': mediaPath,
        'linkUrl': linkUrl,
        'durationSec': durationSec,
        'fade': fade.name,
        'sentAt': sentAt.toIso8601String(),
        'seenAt': seenAt?.toIso8601String(),
        'consumedAt': consumedAt?.toIso8601String(),
        'kept': kept,
        'aiGenerated': aiGenerated,
        'aiSeed': aiSeed,
      };
}
