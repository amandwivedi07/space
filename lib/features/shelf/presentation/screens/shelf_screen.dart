import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/space_app_bar.dart';
import '../../../chat/data/models/space_card.dart';
import '../../../home/data/repositories/spaces_repository.dart';
import '../viewmodels/shelf_viewmodel.dart';
import '../widgets/shelf_card_tile.dart';

/// The shared shelf — what was deliberately kept from a room.
class ShelfScreen extends ConsumerWidget {
  const ShelfScreen({super.key, required this.kind, required this.refId});

  final String kind;
  final String refId;

  String get roomId => '$kind:$refId';

  Future<void> _openCard(
      BuildContext context, WidgetRef ref, SpaceCard card) async {
    final vm = ref.read(shelfViewModelProvider(roomId).notifier);
    await AppBottomSheet.show<void>(
      context,
      eyebrow: AppStrings.keptOnShelf,
      title: AppStrings.keptForever,
      child: Column(
        children: [
          ShelfCardTile(card: card, onTap: () {}),
          const SizedBox(height: 16),
          AppButton(
            label: 'Remove from the shelf',
            variant: AppButtonVariant.soft,
            expanded: true,
            onPressed: () {
              vm.unkeep(card);
              Navigator.of(context).pop();
              AppToast.show(context, AppStrings.removedFromShelf);
            },
          ),
          const SizedBox(height: 8),
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
              if (sure) {
                vm.deleteForEveryone(card);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  AppToast.show(context, AppStrings.deleted);
                }
              }
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
      appBar: SpaceAppBar(
        eyebrow: AppStrings.sharedShelf,
        title: 'With $title',
        onBack: () => context.pop(),
      ),
      body: cards.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: AppStrings.shelfEmptyTitle,
              body: AppStrings.shelfEmptyBody,
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: context.screenWidth > 600 ? 3 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return ShelfCardTile(
                  card: card,
                  senderName: card.isMine
                      ? 'You'
                      : repo.personById(card.senderId)?.name,
                  onTap: () => _openCard(context, ref, card),
                );
              },
            ),
    );
  }
}
