import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

enum RoomMenuChoice { rename, leave }

/// The room's "…" menu. It holds the things you do to the *space* rather than
/// to a card — the header keeps only what you reach for constantly, and
/// leaving is not that.
class RoomMenuSheet extends StatelessWidget {
  const RoomMenuSheet({super.key, required this.isCircle, required this.title});

  final bool isCircle;
  final String title;

  static Future<RoomMenuChoice?> show(
    BuildContext context, {
    required bool isCircle,
    required String title,
  }) =>
      AppBottomSheet.show<RoomMenuChoice>(
        context,
        eyebrow: isCircle ? 'Circle' : 'Space',
        title: title,
        child: RoomMenuSheet(isCircle: isCircle, title: title),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Circles only: a direct space is named after the person in it, and
        // the schema has no name to change.
        if (isCircle)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.ink.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_outlined, size: 19, color: context.ink),
            ),
            title: Text('Rename circle',
                style: AppTypography.display(context.ink, 17)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('EVERYONE IN IT SEES THE NEW NAME',
                  style: AppTypography.mono(context.muted, 8)),
            ),
            onTap: () => Navigator.of(context).pop(RoomMenuChoice.rename),
          ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.colors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.logout_rounded,
                size: 20, color: context.colors.error),
          ),
          title: Text('Leave quietly',
              style: AppTypography.display(context.colors.error, 17)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              isCircle ? 'YOU WILL LEAVE THIS CIRCLE' : 'THIS SPACE CLOSES',
              style: AppTypography.mono(context.muted, 8),
            ),
          ),
          onTap: () => Navigator.of(context).pop(RoomMenuChoice.leave),
        ),
      ],
    );
  }
}
