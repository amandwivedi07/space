import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/fade_options.dart';
import '../../../../core/utils/id_generator.dart';
import '../datasources/chat_mock_datasource.dart';
import '../models/space_card.dart';

/// Chat contract. The realtime implementation keeps this exact surface.
abstract class ChatRepository {
  List<SpaceCard> cardsFor(String roomId);
  Stream<List<SpaceCard>> watchRoom(String roomId);
  SpaceCard send(SpaceCard card);
  void markRoomSeen(String roomId);
  void setKept(String roomId, String cardId, bool kept);
  void consumeViewOnce(String roomId, String cardId);
  void delete(String roomId, String cardId);
}

class MockChatRepository implements ChatRepository {
  MockChatRepository(this._source);

  final ChatMockDataSource _source;
  final _random = Random();

  static const _softReplies = [
    'Mm. I like that.',
    'Say more, slowly.',
    'I read this twice.',
    'Keeping this feeling for a bit.',
    'You always find the words.',
  ];

  @override
  List<SpaceCard> cardsFor(String roomId) => _source.cardsFor(roomId);

  @override
  Stream<List<SpaceCard>> watchRoom(String roomId) =>
      _source.watchRoom(roomId);

  @override
  SpaceCard send(SpaceCard card) {
    _source.add(card);
    // Mock-only warmth: the other side murmurs back once per session.
    final other = _otherSender(card.roomId);
    if (other != null) {
      _source.scheduleReply(
        card.roomId,
        () => SpaceCard(
          id: IdGenerator.next('card'),
          roomId: card.roomId,
          senderId: other,
          type: CardType.text,
          body: _softReplies[_random.nextInt(_softReplies.length)],
          fade: FadeOption.m5,
          sentAt: DateTime.now(),
        ),
      );
    }
    return card;
  }

  String? _otherSender(String roomId) {
    final parts = roomId.split(':');
    if (parts.length != 2) return null;
    // For circles we don't know members here; existing cards tell us.
    if (parts.first == 'circle') {
      final existing =
          cardsFor(roomId).where((c) => !c.isMine).map((c) => c.senderId);
      return existing.isEmpty ? null : existing.first;
    }
    return parts.last;
  }

  @override
  void markRoomSeen(String roomId) => _source.update(
        roomId,
        (c) => c.copyWith(seenAt: DateTime.now()),
        where: (c) => !c.isMine && c.seenAt == null && !c.isViewOnce,
      );

  @override
  void setKept(String roomId, String cardId, bool kept) => _source.update(
        roomId,
        (c) => c.copyWith(kept: kept),
        where: (c) => c.id == cardId,
      );

  @override
  void consumeViewOnce(String roomId, String cardId) => _source.update(
        roomId,
        (c) => c.copyWith(consumedAt: DateTime.now(), seenAt: DateTime.now()),
        where: (c) => c.id == cardId && c.consumedAt == null,
      );

  @override
  void delete(String roomId, String cardId) => _source.remove(roomId, cardId);
}

final chatDataSourceProvider = Provider<ChatMockDataSource>((ref) {
  final source = ChatMockDataSource();
  ref.onDispose(source.dispose);
  return source;
});

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => MockChatRepository(ref.watch(chatDataSourceProvider)),
);
