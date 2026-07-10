import 'package:flutter_test/flutter_test.dart';
import 'package:space_flutter/core/constants/fade_options.dart';
import 'package:space_flutter/features/chat/data/models/space_card.dart';

void main() {
  SpaceCard card({
    FadeOption fade = FadeOption.m1,
    DateTime? seenAt,
    DateTime? consumedAt,
    bool kept = false,
  }) =>
      SpaceCard(
        id: 'c1',
        roomId: 'person:elena',
        senderId: 'me',
        type: CardType.text,
        body: 'hello',
        fade: fade,
        sentAt: DateTime.now(),
        seenAt: seenAt,
        consumedAt: consumedAt,
        kept: kept,
      );

  group('SpaceCard fade engine', () {
    test('unseen card never expires', () {
      expect(card().expiresAt, isNull);
      expect(card().expired, isFalse);
    });

    test('seen card expires after its fade duration', () {
      final seen = DateTime.now().subtract(const Duration(seconds: 90));
      final c = card(fade: FadeOption.m1, seenAt: seen);
      expect(c.expired, isTrue);
    });

    test('seen card within its window is alive with remaining time', () {
      final c = card(fade: FadeOption.m5, seenAt: DateTime.now());
      expect(c.expired, isFalse);
      expect(c.remaining, isNotNull);
      expect(c.remaining!.inSeconds, greaterThan(200));
    });

    test('kept cards never expire', () {
      final seen = DateTime.now().subtract(const Duration(hours: 2));
      final c = card(fade: FadeOption.s10, seenAt: seen, kept: true);
      expect(c.expiresAt, isNull);
      expect(c.expired, isFalse);
    });

    test('view-once expires shortly after being consumed', () {
      final c = card(
        fade: FadeOption.viewOnce,
        consumedAt: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(c.expired, isTrue);
    });

    test('json round trip preserves the card', () {
      final original = card(fade: FadeOption.m15, seenAt: DateTime.now());
      final restored = SpaceCard.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.fade, FadeOption.m15);
      expect(restored.type, CardType.text);
    });
  });
}
