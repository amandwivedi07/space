import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/helpers/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../chat/data/models/space_card.dart';
import '../../../chat/presentation/widgets/card_content.dart';

/// One kept memory on the shelf grid.
class ShelfCardTile extends StatelessWidget {
  const ShelfCardTile({
    super.key,
    required this.card,
    this.senderName,
    required this.onTap,
  });

  final SpaceCard card;
  final String? senderName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CardContent(card: card),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.bookmark_rounded, size: 12, color: context.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${senderName ?? (card.isMine ? 'You' : 'Them')} · ${DateFormatter.cardStamp(card.sentAt)}',
                  style: context.text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
