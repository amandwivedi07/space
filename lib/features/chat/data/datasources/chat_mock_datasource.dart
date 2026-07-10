import 'dart:async';

import '../../../../core/constants/app_constants.dart';
import '../models/space_card.dart';
import 'chat_seed_data.dart';

/// In-memory reactive card store with the fade engine: a 1s sweep removes
/// expired cards. A realtime datasource will expose the same streams.
class ChatMockDataSource {
  ChatMockDataSource() : _rooms = ChatSeedData.rooms() {
    _sweeper = Timer.periodic(AppConstants.fadeTick, (_) => _sweep());
  }

  final Map<String, List<SpaceCard>> _rooms;
  final Map<String, StreamController<List<SpaceCard>>> _controllers = {};
  final Set<String> _replied = {};
  late final Timer _sweeper;

  StreamController<List<SpaceCard>> _controllerFor(String roomId) =>
      _controllers.putIfAbsent(
          roomId, () => StreamController<List<SpaceCard>>.broadcast());

  List<SpaceCard> cardsFor(String roomId) =>
      List.unmodifiable(_rooms[roomId] ?? const []);

  Stream<List<SpaceCard>> watchRoom(String roomId) =>
      _controllerFor(roomId).stream;

  void _emit(String roomId) => _controllerFor(roomId).add(cardsFor(roomId));

  void _sweep() {
    for (final roomId in _rooms.keys) {
      final before = _rooms[roomId]!.length;
      _rooms[roomId] = _rooms[roomId]!.where((c) => !c.expired).toList();
      if (_rooms[roomId]!.length != before) _emit(roomId);
    }
  }

  void add(SpaceCard card) {
    _rooms.putIfAbsent(card.roomId, () => []).add(card);
    _emit(card.roomId);
  }

  void update(String roomId, SpaceCard Function(SpaceCard) transform,
      {bool Function(SpaceCard)? where}) {
    final cards = _rooms[roomId];
    if (cards == null) return;
    _rooms[roomId] = [
      for (final card in cards)
        (where == null || where(card)) ? transform(card) : card,
    ];
    _emit(roomId);
  }

  void remove(String roomId, String cardId) {
    _rooms[roomId]?.removeWhere((c) => c.id == cardId);
    _emit(roomId);
  }

  /// One gentle simulated reply per room per session (mock-layer only).
  void scheduleReply(String roomId, SpaceCard Function() maker) {
    if (_replied.contains(roomId)) return;
    _replied.add(roomId);
    Timer(AppConstants.mockReplyDelay, () {
      if (_controllers[roomId]?.isClosed ?? true) return;
      add(maker());
    });
  }

  void dispose() {
    _sweeper.cancel();
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}
