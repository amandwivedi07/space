import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/constants/presence.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../authentication/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/data/models/person.dart';
import '../../../space_ai/data/repositories/space_ai_repository.dart';
import '../../../home/data/repositories/spaces_repository.dart';
import '../../data/models/space_card.dart';
import '../viewmodels/room_viewmodel.dart';
import '../widgets/composer.dart';
import '../widgets/pending_notice.dart';
import '../widgets/space_ai_pill.dart';
import '../widgets/empty_room_view.dart';
import '../widgets/story_card_view.dart';
import '../widgets/story_footer.dart';
import '../widgets/story_header.dart';
import '../widgets/story_progress_bar.dart';

/// A room as a story viewer — one card at a time on a dark ambient stage.
/// Tap right to advance, left to go back, swipe down to leave quietly.
class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen(
      {super.key, required this.kind, required this.refId, this.initialCardId});

  final String kind; // 'person' | 'circle'
  final String refId;

  /// When set, the story opens on this card — how a shelf keepsake is
  /// reopened "exactly as it first arrived".
  final String? initialCardId;

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  int _index = 0;
  Timer? _ticker;
  bool _jumpedToInitial = false;

  String get roomId => '${widget.kind}:${widget.refId}';
  bool get isCircle => widget.kind == 'circle';

  @override
  void initState() {
    super.initState();
    // One shared clock drives the progress bar and the "8S LEFT" meta.
    _ticker = Timer.periodic(AppConstants.fadeTick, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  List<SpaceCard> _sorted(List<SpaceCard> cards) =>
      cards.toList()..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  void _tap(TapUpDetails details, List<SpaceCard> cards) {
    if (cards.isEmpty) return;
    final card = cards[_index];
    if (card.isViewOnce && card.consumedAt == null) {
      ref.read(roomViewModelProvider(roomId).notifier).revealViewOnce(card);
      return;
    }
    final width = MediaQuery.sizeOf(context).width;
    setState(() {
      if (details.globalPosition.dx < width / 3) {
        if (_index > 0) _index--;
      } else if (_index < cards.length - 1) {
        _index++;
      }
    });
  }

  Future<void> _delete(SpaceCard card) async {
    final sure = await AppDialog.confirm(
      context,
      title: AppStrings.deleteCard,
      body: AppStrings.deleteCardConfirm,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (sure && mounted) {
      final result =
          await ref.read(roomViewModelProvider(roomId).notifier).deleteCard(card);
      if (!mounted) return;
      result.when(
        success: (_) => AppToast.show(context, AppStrings.deleted),
        // The card reappears when the server refuses — explain why.
        failure: (message) => AppDialog.alert(context,
            title: "Couldn't delete it", body: message),
      );
    }
  }

  Future<void> _toggleKeep(SpaceCard card) async {
    final wasKept = card.kept;
    final result =
        await ref.read(roomViewModelProvider(roomId).notifier).toggleKeep(card);
    if (!mounted) return;
    result.when(
      success: (_) => AppToast.show(
        context,
        wasKept ? AppStrings.removedFromShelf : AppStrings.keptOnShelf,
        icon: wasKept ? null : Icons.bookmark_rounded,
      ),
      failure: (message) => AppDialog.alert(context,
          title: wasKept ? "Couldn't remove it" : "Couldn't keep it",
          body: message),
    );
  }

  String _roomTitle() {
    final repo = ref.read(spacesRepositoryProvider);
    return isCircle
        ? repo.circleById(widget.refId)?.name ?? 'A quiet circle'
        : repo.personById(widget.refId)?.name ?? 'Someone';
  }

  Presence _roomPresence() {
    final repo = ref.read(spacesRepositoryProvider);
    return isCircle
        ? repo.circleById(widget.refId)?.presence ?? Presence.away
        : repo.personById(widget.refId)?.presence ?? Presence.away;
  }

  (String, String) _senderOf(SpaceCard? card) {
    final repo = ref.read(spacesRepositoryProvider);
    if (card == null || !card.isMine) {
      final person = repo.personById(
        card?.senderId ?? (isCircle ? '' : widget.refId),
      );
      if (person != null) return (person.name, person.paletteId);
      final circle = isCircle ? repo.circleById(widget.refId) : null;
      return (circle?.name ?? 'Someone', 'iris');
    }
    final me = ref.read(authViewModelProvider).user;
    return ('You', me?.paletteId ?? 'ember');
  }

  /// A direct space that is still an invitation: nothing may be sent yet.
  /// Watched, not read — the room must unlock the moment they accept, without
  /// the reader having to back out and come in again.
  SpaceRequest? _pendingRequest() {
    if (widget.kind != 'person') return null;
    final live = ref.watch(peopleProvider).valueOrNull;
    Person? person;
    for (final p in live ?? const <Person>[]) {
      if (p.id == widget.refId) {
        person = p;
        break;
      }
    }
    // Before the first stream event, fall back to the cached snapshot.
    person ??= ref.read(spacesRepositoryProvider).personById(widget.refId);
    if (person == null || !person.awaitingAnswer) return null;
    return person.request;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomViewModelProvider(roomId));
    ref.listen(roomViewModelProvider(roomId), (prev, next) {
      // Jump to my card the moment it is sent.
      if ((prev?.cards.length ?? 0) < next.cards.length &&
          _sorted(next.cards).last.isMine) {
        setState(() => _index = next.cards.length - 1);
      }
    });

    final cards = _sorted(state.cards);
    // Land on the keepsake the shelf sent us to, once, when cards first load.
    if (!_jumpedToInitial && widget.initialCardId != null && cards.isNotEmpty) {
      _jumpedToInitial = true;
      final at = cards.indexWhere((c) => c.id == widget.initialCardId);
      if (at >= 0) _index = at;
    }
    if (_index > cards.length - 1) _index = (cards.length - 1).clamp(0, 999);
    final current = cards.isEmpty ? null : cards[_index];
    final (senderName, paletteId) = _senderOf(current);
    final palette = SpacePalette.byId(paletteId);
    final background = context.theme.scaffoldBackgroundColor;
    // Ambient stage tinted by the sender's palette, in the active theme.
    final tint = context.isDark
        ? Color.lerp(background, palette.to, 0.22)!
        : Color.lerp(background, palette.from, 0.30)!;

    return Scaffold(
      backgroundColor: background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tint, background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              StoryProgressBar(cards: cards, index: _index),
              StoryHeader(
                senderName: senderName,
                paletteId: paletteId,
                card: current,
                onShelf: () =>
                    context.push(RouteNames.shelf(widget.kind, widget.refId)),
                onClose: () => context.pop(),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _tap(details, cards),
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) > 500) context.pop();
                  },
                  child: current == null
                      ? EmptyRoomView(
                          name: senderName == 'You' ? _roomTitle() : senderName,
                          paletteId: paletteId,
                          presence: _roomPresence(),
                          fade: state.fade,
                          onOpenAi:
                              (ref.watch(spaceAiAvailableProvider).valueOrNull ??
                                      false)
                                  ? () => Composer.openSpaceAi(
                                      context, ref, roomId)
                                  : null,
                        )
                      : StoryCardView(card: current),
                ),
              ),
              // The invitation to answer with SpaceAI — pinned above the
              // footer, only when a card is showing and the room is open.
              if (current != null &&
                  _pendingRequest() == null &&
                  (ref.watch(spaceAiAvailableProvider).valueOrNull ?? false))
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 20, 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SpaceAiPill(
                      onTap: () => Composer.openSpaceAi(context, ref, roomId),
                    ),
                  ),
                ),
              if (current != null)
                StoryFooter(
                  card: current,
                  index: _index,
                  total: cards.length,
                  onReact: (emoji) => ref
                      .read(roomViewModelProvider(roomId).notifier)
                      .react(current, emoji),
                  onToggleKeep: () => _toggleKeep(current),
                  onDelete: () => _delete(current),
                ),
              if (_pendingRequest() case final request?)
                PendingNotice(request: request, name: _roomTitle())
              else
                Composer(
                  roomId: roomId,
                  // First name only: the field is one line now, and a full
                  // name pushed the hint into an ellipsis every time.
                  hint: 'Type to ${_roomTitle().split(RegExp(r"\s+")).first}…',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
