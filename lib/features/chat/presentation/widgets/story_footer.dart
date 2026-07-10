import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/space_card.dart';

/// Bottom story rail: emoji reactions, KEEP THIS / DELETE pills, "1 / 3".
class StoryFooter extends StatelessWidget {
  const StoryFooter({
    super.key,
    required this.card,
    required this.index,
    required this.total,
    required this.onReact,
    required this.onToggleKeep,
    required this.onDelete,
  });

  static const _reactions = ['❤️', '😂', '😮', '😢', '🔥', '👏'];

  final SpaceCard card;
  final int index;
  final int total;
  final ValueChanged<String> onReact;
  final VoidCallback onToggleKeep;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.ink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final emoji in _reactions)
                  GestureDetector(
                    onTap: () => onReact(emoji),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Pill(
                label: card.kept ? '✓ KEPT' : '+ KEEP THIS',
                emphasized: card.kept,
                onTap: onToggleKeep,
              ),
              if (card.isMine) ...[
                const SizedBox(width: 8),
                _Pill(label: 'DELETE', onTap: onDelete),
              ],
              const Spacer(),
              Text('${index + 1} / $total',
                  style: AppTypography.mono(context.muted, 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.emphasized = false});

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized ? context.ink : context.ink.withValues(alpha: 0.07),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: AppTypography.mono(
                emphasized
                    ? context.theme.scaffoldBackgroundColor
                    : context.ink,
                9),
          ),
        ),
      ),
    );
  }
}
