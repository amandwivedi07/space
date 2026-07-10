import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../authentication/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/data/repositories/spaces_repository.dart';
import '../../data/models/space_card.dart';
import '../viewmodels/room_viewmodel.dart';
import '../widgets/composer.dart';
import '../widgets/story_card_view.dart';
import '../widgets/story_footer.dart';
import '../widgets/story_header.dart';
import '../widgets/story_progress_bar.dart';

/// A room as a story viewer — one card at a time on a dark ambient stage.
/// Tap right to advance, left to go back, swipe down to leave quietly.
class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key, required this.kind, required this.refId});

  final String kind; // 'person' | 'circle'
  final String refId;

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  int _index = 0;
  Timer? _ticker;

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
      ref.read(roomViewModelProvider(roomId).notifier).deleteCard(card);
      AppToast.show(context, AppStrings.deleted);
    }
  }

  void _toggleKeep(SpaceCard card) {
    ref.read(roomViewModelProvider(roomId).notifier).toggleKeep(card);
    AppToast.show(
      context,
      card.kept ? AppStrings.removedFromShelf : AppStrings.keptOnShelf,
      icon: card.kept ? null : Icons.bookmark_rounded,
    );
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
                      ? Center(
                          child: Text(
                            AppStrings.sayTheFirstThing,
                            style: AppTypography.display(context.muted, 22),
                          ),
                        )
                      : StoryCardView(card: current),
                ),
              ),
              if (current != null)
                StoryFooter(
                  card: current,
                  index: _index,
                  total: cards.length,
                  onReact: (emoji) => ref
                      .read(roomViewModelProvider(roomId).notifier)
                      .sendText(emoji),
                  onToggleKeep: () => _toggleKeep(current),
                  onDelete: () => _delete(current),
                ),
              Composer(roomId: roomId, hint: AppStrings.saySomething),
            ],
          ),
        ),
      ),
    );
  }
}
