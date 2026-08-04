import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../chat/data/models/space_card.dart';
import '../../../home/data/models/person.dart';
import '../../../home/data/repositories/spaces_repository.dart';
import '../viewmodels/shelf_viewmodel.dart';
import '../widgets/keepsake_card.dart';

/// The shared shelf — what was deliberately kept while everything else
/// quietly disappeared.
class ShelfScreen extends ConsumerWidget {
  const ShelfScreen({super.key, required this.kind, required this.refId});

  final String kind;
  final String refId;

  String get roomId => '$kind:$refId';

  Person? _sender(WidgetRef ref, SpaceCard card) =>
      ref.read(spacesRepositoryProvider).personById(card.senderId);

  String _senderName(WidgetRef ref, SpaceCard card) =>
      card.isMine ? 'You' : _sender(ref, card)?.name ?? 'Someone';

  KeepsakeCard _keepsake(WidgetRef ref, SpaceCard card, int index, int total,
          {required VoidCallback onTap,
          VoidCallback? onLongPress,
          VoidCallback? onMenu}) =>
      KeepsakeCard(
        card: card,
        index: index,
        total: total,
        onTap: onTap,
        onLongPress: onLongPress,
        onMenu: onMenu,
        senderName: _senderName(ref, card),
        senderAvatarUrl: card.isMine ? '' : _sender(ref, card)?.avatarUrl ?? '',
        senderPaletteId: _sender(ref, card)?.paletteId ?? 'ember',
      );

  Future<void> _openCard(BuildContext context, WidgetRef ref, SpaceCard card,
      int index, int total) async {
    final vm = ref.read(shelfViewModelProvider(roomId).notifier);
    // Held across the awaits: the card being acted on disappears from the
    // list, so nothing tied to its element can be trusted afterwards.
    final navigator = Navigator.of(context);
    final messenger = context;
    await AppBottomSheet.show<void>(
      context,
      eyebrow: AppStrings.keptOnShelf,
      title: AppStrings.keptForever,
      child: Column(
        children: [
          _keepsake(ref, card, index, total, onTap: () {}),
          const SizedBox(height: 16),
          AppButton(
            label: 'Remove from the shelf',
            variant: AppButtonVariant.soft,
            expanded: true,
            onPressed: () async {
              // Unkeeping puts the card back on its fade clock — worth a
              // pause, because "forever" quietly stops applying.
              final sure = await AppDialog.confirm(
                context,
                title: 'Remove from the shelf?',
                body: 'It goes back to fading like any other card, '
                    'and may soon be gone.',
                confirmLabel: 'Remove',
              );
              if (!sure) return;
              final result = await vm.unkeep(card);
              navigator.pop();
              if (!messenger.mounted) return;
              result.when(
                success: (_) =>
                    AppToast.show(messenger, AppStrings.removedFromShelf),
                failure: (message) => AppDialog.alert(messenger,
                    title: "Couldn't remove it", body: message),
              );
            },
          ),
          const SizedBox(height: 8),
          if (card.isMine)
            AppButton(
              label: AppStrings.deleteCard,
              variant: AppButtonVariant.danger,
              expanded: true,
              onPressed: () async {
                final sure = await AppDialog.confirm(
                  context,
                  title: AppStrings.deleteCard,
                  body: AppStrings.deleteCardConfirm,
                  confirmLabel: AppStrings.delete,
                  destructive: true,
                );
                if (!sure) return;
                final result = await vm.deleteForEveryone(card);
                navigator.pop();
                if (!messenger.mounted) return;
                result.when(
                  success: (_) => AppToast.show(messenger, AppStrings.deleted),
                  // The card is already back on screen — say why.
                  failure: (message) => AppDialog.alert(messenger,
                      title: "Couldn't delete it", body: message),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(shelfViewModelProvider(roomId));
    final repo = ref.read(spacesRepositoryProvider);
    final title = kind == 'circle'
        ? repo.circleById(refId)?.name ?? 'A circle'
        : repo.personById(refId)?.name ?? 'Someone';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.pop(),
                      child: Text('←  BACK TO SPACE',
                          style: AppTypography.mono(context.muted, 10)),
                    ),
                    const SizedBox(height: 26),
                    // Not "shared": a keep is private to whoever made it, so
                    // this shelf only ever holds your own.
                    Text('YOUR SHELF · WITH ${title.toUpperCase()}',
                        style:
                            AppTypography.mono(const Color(0xFFB05C3F), 9)),
                    const SizedBox(height: 12),
                    Text('What you chose\nto keep.',
                        style: AppTypography.display(context.ink, 34)),
                    const SizedBox(height: 12),
                    Text(
                      'Everything else has quietly disappeared. Only you can '
                      'see what you kept. Tap any keepsake to open it exactly '
                      'as it first arrived.',
                      style: context.text.bodySmall?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text('${cards.length}',
                            style: AppTypography.display(context.ink, 16)),
                        const SizedBox(width: 5),
                        Text('KEPT',
                            style: AppTypography.mono(context.muted, 9)),
                        const Spacer(),
                        Text('FOREVER, UNLESS REMOVED',
                            style: AppTypography.mono(context.muted, 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (cards.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                  child: Column(
                    children: [
                      Text('Nothing kept yet.',
                          style: AppTypography.display(context.ink, 20)),
                      const SizedBox(height: 8),
                      Text(
                        'In any story, tap keep this and it will rest here.',
                        style: context.text.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  // NOTE: deliberately ignoring the item context — deleting a
                  // keepsake unmounts it mid-flow, and anything awaiting on it
                  // would silently give up. The screen's context outlives it.
                  itemBuilder: (_, index) => _keepsake(
                    ref,
                    cards[index],
                    index,
                    cards.length,
                    // Reopen it exactly as it first arrived — in the room,
                    // where keep/remove and delete already live. Long-press
                    // for quick remove/delete without leaving the shelf.
                    onTap: () => context.push(
                        RouteNames.roomAtCard(kind, refId, cards[index].id)),
                    onLongPress: () => _openCard(
                        context, ref, cards[index], index, cards.length),
                    onMenu: () => _openCard(
                        context, ref, cards[index], index, cards.length),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 44),
                child: Center(
                  child: Text('fin',
                      style: AppTypography.display(context.muted, 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
