import 'dart:async';

import '../../../../core/constants/fade_options.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/logger_service.dart';
import '../models/space_card.dart';
import 'chat_repository.dart';

/// Backend-backed cards: GET /spaces/{id}/cards polled every 3s per open room.
/// roomId format stays `person:spaceId` / `circle:spaceId`.
class ApiChatRepository implements ChatRepository {
  ApiChatRepository(this._client, this._myUserId,
      {Stream<Map<String, dynamic>>? events}) {
    _eventsSub = events?.listen((event) {
      if (event['type'] != 'cards.changed') return;
      final spaceId = event['space_id'] as String?;
      if (spaceId == null) return;
      // Refresh any open room bound to this space (person: or circle:).
      for (final roomId in _pollers.keys) {
        if (_spaceOf(roomId) == spaceId) _poll(roomId);
      }
    });
  }

  StreamSubscription<Map<String, dynamic>>? _eventsSub;

  final ApiClient _client;
  final String Function() _myUserId;

  final Map<String, List<SpaceCard>> _cache = {};
  final Map<String, StreamController<List<SpaceCard>>> _controllers = {};
  final Map<String, Timer> _pollers = {};
  final Set<String> _markingSeen = {}; // single-flight per room

  static String _spaceOf(String roomId) => roomId.split(':').last;

  // ---- mapping ----

  static const _typeFromApi = {
    'text': CardType.text, 'photo': CardType.photo, 'video': CardType.video,
    'voice': CardType.voice, 'link': CardType.link, 'file': CardType.file,
    'ai_image': CardType.aiImage, 'ai_video': CardType.aiVideo,
  };
  static const _typeToApi = {
    CardType.text: 'text', CardType.photo: 'photo', CardType.video: 'video',
    CardType.voice: 'voice', CardType.link: 'link', CardType.file: 'file',
    CardType.aiImage: 'ai_image', CardType.aiVideo: 'ai_video',
  };

  SpaceCard _fromApi(String roomId, Map<String, dynamic> json) {
    final senderId = json['sender_id'] as String;
    return SpaceCard(
      id: json['id'] as String,
      roomId: roomId,
      senderId: senderId == _myUserId() ? 'me' : senderId,
      type: _typeFromApi[json['type']] ?? CardType.text,
      body: json['body'] as String? ?? '',
      mediaPath: json['media_url'] as String?,
      linkUrl: json['link_url'] as String?,
      durationSec: (json['duration_sec'] as num?)?.toInt() ?? 0,
      fade: FadeOption.fromId(json['fade'] as String?),
      sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      seenAt: DateTime.tryParse(json['seen_at'] as String? ?? '')?.toLocal(),
      consumedAt:
          DateTime.tryParse(json['consumed_at'] as String? ?? '')?.toLocal(),
      kept: json['kept'] as bool? ?? false,
      aiGenerated: json['ai_generated'] as bool? ?? false,
      aiSeed: (json['ai_seed'] as num?)?.toInt() ?? 0,
      reactions: List<String>.from(json['reactions'] as List? ?? const []),
    );
  }

  Future<void> _poll(String roomId) async {
    try {
      final data = await _client.get('/spaces/${_spaceOf(roomId)}/cards')
          as List<dynamic>?;
      final cards = (data ?? const [])
          .cast<Map<String, dynamic>>()
          .map((json) => _fromApi(roomId, json))
          .toList();
      _cache[roomId] = cards;
      _controllers[roomId]?.add(List.unmodifiable(cards));

      // Room is open (active poller) and new cards arrived unseen → their
      // fade clocks must start now, not on the next room open.
      final hasUnseen = cards
          .any((c) => !c.isMine && c.seenAt == null && !c.isViewOnce);
      if (hasUnseen &&
          _pollers.containsKey(roomId) &&
          !_markingSeen.contains(roomId)) {
        _markingSeen.add(roomId);
        _client
            .post('/spaces/${_spaceOf(roomId)}/seen')
            .then((_) => _poll(roomId))
            .catchError((e) => Log.w('auto-seen failed: $e'))
            .whenComplete(() => _markingSeen.remove(roomId));
      }
    } on ApiException catch (e) {
      Log.w('cards poll failed for $roomId: $e');
    }
  }

  // ---- ChatRepository ----

  @override
  List<SpaceCard> cardsFor(String roomId) =>
      List.unmodifiable(_cache[roomId] ?? const []);

  @override
  Stream<List<SpaceCard>> watchRoom(String roomId) {
    final controller = _controllers.putIfAbsent(roomId, () {
      final ctrl = StreamController<List<SpaceCard>>.broadcast(
        onListen: () {
          // 30s safety net — WebSocket events do the real-time work.
          _pollers[roomId] ??= Timer.periodic(
              const Duration(seconds: 30), (_) => _poll(roomId));
          _poll(roomId);
        },
        onCancel: () {
          _pollers.remove(roomId)?.cancel();
        },
      );
      return ctrl;
    });
    return controller.stream;
  }

  @override
  SpaceCard send(SpaceCard card) {
    _client.post('/spaces/${_spaceOf(card.roomId)}/cards', body: {
      'type': _typeToApi[card.type],
      'body': card.body,
      if (card.mediaPath != null && card.mediaPath!.startsWith('http'))
        'media_url': card.mediaPath,
      if (card.linkUrl != null) 'link_url': card.linkUrl,
      'duration_sec': card.durationSec,
      'fade': card.fade.name,
      'ai_generated': card.aiGenerated,
      'ai_seed': card.aiSeed,
    }).then((_) => _poll(card.roomId)).catchError((e) {
      Log.w('send failed: $e');
    });
    // Optimistic echo so the story view advances instantly.
    _cache[card.roomId] = [...?_cache[card.roomId], card];
    _controllers[card.roomId]?.add(cardsFor(card.roomId));
    return card;
  }

  @override
  void markRoomSeen(String roomId) {
    _client
        .post('/spaces/${_spaceOf(roomId)}/seen')
        .then((_) => _poll(roomId))
        .catchError((e) => Log.w('seen failed: $e'));
  }

  @override
  void setKept(String roomId, String cardId, bool kept) {
    final call = kept
        ? _client.post('/cards/$cardId/keep')
        : _client.delete('/cards/$cardId/keep');
    call.then((_) => _poll(roomId)).catchError((e) => Log.w('keep failed: $e'));
  }

  @override
  void consumeViewOnce(String roomId, String cardId) {
    _client
        .post('/cards/$cardId/consume')
        .then((_) => _poll(roomId))
        .catchError((e) => Log.w('consume failed: $e'));
  }

  @override
  void delete(String roomId, String cardId) {
    _cache[roomId]?.removeWhere((c) => c.id == cardId);
    _controllers[roomId]?.add(cardsFor(roomId));
    _client
        .delete('/cards/$cardId')
        .then((_) => _poll(roomId))
        .catchError((e) => Log.w('delete failed: $e'));
  }

  @override
  void react(String roomId, String cardId, String emoji) {
    _client
        .post('/cards/$cardId/reactions', body: {'emoji': emoji})
        .then((_) => _poll(roomId))
        .catchError((e) => Log.w('react failed: $e'));
  }

  void dispose() {
    _eventsSub?.cancel();
    for (final t in _pollers.values) {
      t.cancel();
    }
    for (final c in _controllers.values) {
      c.close();
    }
  }
}
