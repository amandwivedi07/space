import 'package:flutter/material.dart';

import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/extensions/datetime_x.dart';
import '../../../../core/helpers/date_formatter.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/space_card.dart';

/// Story header: who this card is from, when, and how long it has left, plus
/// delete, the shared shelf and a single way out. Keeping lives on the
/// labelled KEEP THIS pill down in the rail, where the wording can say what
/// tapping it will do.
class StoryHeader extends StatelessWidget {
  const StoryHeader({
    super.key,
    required this.senderName,
    required this.paletteId,
    this.card,
    required this.onShelf,
    required this.onClose,
    this.onDelete,
  });

  final String senderName;
  final String paletteId;
  final SpaceCard? card;
  final VoidCallback onShelf;
  final VoidCallback onClose;

  /// Deleting is a considered act, so it lives up here with the other
  /// room-level controls — null on cards that are not mine to take back.
  final VoidCallback? onDelete;

  String get _meta {
    final c = card;
    if (c == null) return 'A QUIET ROOM';
    final ago = c.sentAt.agoLabel.toUpperCase();
    if (c.kept) return '$ago · KEPT ON THE SHELF';
    final remaining = c.remaining;
    if (remaining != null) {
      return '$ago · ${DateFormatter.remaining(remaining).toUpperCase()} LEFT';
    }
    return '$ago · ${c.fade.sentenceLabel.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          AppAvatar(
            name: senderName,
            palette: SpacePalette.byId(paletteId),
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(senderName,
                    style: AppTypography.display(context.ink, 20),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(_meta,
                    style: AppTypography.mono(context.muted, 9),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: context.muted),
            ),
          IconButton(
            tooltip: 'Your shelf',
            onPressed: onShelf,
            icon: Icon(Icons.collections_bookmark_outlined,
                size: 20, color: context.ink),
          ),
          IconButton(
            tooltip: 'Leave quietly',
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 21, color: context.ink),
          ),
        ],
      ),
    );
  }
}
