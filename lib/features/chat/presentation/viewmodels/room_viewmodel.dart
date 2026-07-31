import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/fade_options.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../profile/presentation/viewmodels/settings_viewmodel.dart';
import '../../data/models/space_card.dart';
import '../../data/repositories/chat_repository.dart';

/// State of one open room, keyed by roomId ("person:elena" / "circle:kyoto-trip").
class RoomState {
  const RoomState({
    this.cards = const [],
    this.fade = FadeOption.m1,
  });

  final List<SpaceCard> cards;
  final FadeOption fade;

  RoomState copyWith({List<SpaceCard>? cards, FadeOption? fade}) =>
      RoomState(cards: cards ?? this.cards, fade: fade ?? this.fade);
}

class RoomViewModel extends AutoDisposeFamilyNotifier<RoomState, String> {
  ChatRepository get _repo => ref.read(chatRepositoryProvider);
  String get roomId => arg;

  @override
  RoomState build(String arg) {
    final repo = ref.watch(chatRepositoryProvider);
    final sub = repo.watchRoom(arg).listen((cards) => state = state.copyWith(
        // Never show a card whose fade window has closed, even if the server
        // sweep hasn't caught it yet.
        cards: cards.where((c) => !c.expired).toList()));
    ref.onDispose(sub.cancel);

    // Opening the room is "seeing" it — fade clocks start now.
    Future.microtask(() => repo.markRoomSeen(arg));

    final defaultFade = ref.read(settingsViewModelProvider).defaultFade;
    return RoomState(cards: repo.cardsFor(arg), fade: defaultFade);
  }

  void setFade(FadeOption fade) => state = state.copyWith(fade: fade);

  SpaceCard _draft(CardType type,
          {String body = '',
          String? mediaPath,
          String? linkUrl,
          int durationSec = 0,
          bool aiGenerated = false,
          int aiSeed = 0}) =>
      SpaceCard(
        id: IdGenerator.next('card'),
        roomId: roomId,
        senderId: 'me',
        type: type,
        body: body,
        mediaPath: mediaPath,
        linkUrl: linkUrl,
        durationSec: durationSec,
        fade: state.fade,
        sentAt: DateTime.now(),
        // My own card is "seen" by me; the server sets the authoritative
        // clock and the next refresh replaces this optimistic copy.
        seenAt: DateTime.now(),
        aiGenerated: aiGenerated,
        aiSeed: aiSeed,
      );

  void sendText(String body) {
    if (body.trim().isEmpty) return;
    _repo.send(_draft(CardType.text, body: body.trim()));
  }

  /// A SpaceAI draft sent as-is — carries the "Sent with SpaceAI." mark.
  void sendAiText(String body) {
    if (body.trim().isEmpty) return;
    _repo.send(_draft(CardType.text, body: body.trim(), aiGenerated: true));
  }


  void sendPhoto(String path, {String caption = ''}) =>
      _repo.send(_draft(CardType.photo, mediaPath: path, body: caption));

  void sendVideo(String path, {String caption = ''}) =>
      _repo.send(_draft(CardType.video, mediaPath: path, body: caption));

  void sendVoice(int seconds, {String? url}) => _repo.send(
      _draft(CardType.voice, durationSec: seconds, mediaPath: url));

  void sendLink(String url, {String comment = ''}) =>
      _repo.send(_draft(CardType.link, linkUrl: url, body: comment));

  /// The picture already lives in our storage, so this is an ordinary media
  /// card that happens to be flagged as generated. The prompt is deliberately
  /// not sent: it was how you asked for the image, not a caption for it.
  void sendAiImage(String url) => _repo.send(
      _draft(CardType.aiImage, mediaPath: url, aiGenerated: true));

  void toggleKeep(SpaceCard card) =>
      _repo.setKept(roomId, card.id, !card.kept);

  void revealViewOnce(SpaceCard card) =>
      _repo.consumeViewOnce(roomId, card.id);

  void deleteCard(SpaceCard card) => _repo.delete(roomId, card.id);

  void react(SpaceCard card, String emoji) => _repo.react(roomId, card.id, emoji);
}

final roomViewModelProvider = AutoDisposeNotifierProviderFamily<RoomViewModel,
    RoomState, String>(RoomViewModel.new);
