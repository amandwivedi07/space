import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/data/models/space_card.dart';
import '../../../chat/data/repositories/chat_repository.dart';

/// Shelf contract — the kept memories of a room.
/// Backed today by the chat store (kept cards); later by GET /shelf/:roomId.
abstract class ShelfRepository {
  List<SpaceCard> keptFor(String roomId);
  Stream<List<SpaceCard>> watchShelf(String roomId);
  void unkeep(String roomId, String cardId);
  void deleteForEveryone(String roomId, String cardId);
}

class ChatBackedShelfRepository implements ShelfRepository {
  ChatBackedShelfRepository(this._chat);

  final ChatRepository _chat;

  List<SpaceCard> _onlyKept(List<SpaceCard> cards) =>
      cards.where((c) => c.kept).toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

  @override
  List<SpaceCard> keptFor(String roomId) => _onlyKept(_chat.cardsFor(roomId));

  @override
  Stream<List<SpaceCard>> watchShelf(String roomId) =>
      _chat.watchRoom(roomId).map(_onlyKept);

  @override
  void unkeep(String roomId, String cardId) =>
      _chat.setKept(roomId, cardId, false);

  @override
  void deleteForEveryone(String roomId, String cardId) =>
      _chat.delete(roomId, cardId);
}

final shelfRepositoryProvider = Provider<ShelfRepository>(
  (ref) => ChatBackedShelfRepository(ref.watch(chatRepositoryProvider)),
);
