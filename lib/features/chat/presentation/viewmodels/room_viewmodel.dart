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
    final sub = repo
        .watchRoom(arg)
        .listen((cards) => state = state.copyWith(cards: cards));
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
        seenAt: DateTime.now(), // demo: my cards start fading immediately
        aiGenerated: aiGenerated,
        aiSeed: aiSeed,
      );

  void sendText(String body) {
    if (body.trim().isEmpty) return;
    _repo.send(_draft(CardType.text, body: body.trim()));
  }

  void sendPhoto(String path, {String caption = ''}) =>
      _repo.send(_draft(CardType.photo, mediaPath: path, body: caption));

  void sendVideo(String path, {String caption = ''}) =>
      _repo.send(_draft(CardType.video, mediaPath: path, body: caption));

  void sendVoice(int seconds) =>
      _repo.send(_draft(CardType.voice, durationSec: seconds));

  void sendLink(String url, {String comment = ''}) =>
      _repo.send(_draft(CardType.link, linkUrl: url, body: comment));

  void sendAiImage(String prompt, int seed) => _repo.send(_draft(
      CardType.aiImage, body: prompt, aiGenerated: true, aiSeed: seed));

  void sendAiVideo(String prompt, int seed) => _repo.send(_draft(
      CardType.aiVideo, body: prompt, aiGenerated: true, aiSeed: seed));

  void toggleKeep(SpaceCard card) =>
      _repo.setKept(roomId, card.id, !card.kept);

  void revealViewOnce(SpaceCard card) =>
      _repo.consumeViewOnce(roomId, card.id);

  void deleteCard(SpaceCard card) => _repo.delete(roomId, card.id);
}

final roomViewModelProvider = AutoDisposeNotifierProviderFamily<RoomViewModel,
    RoomState, String>(RoomViewModel.new);
