import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/space_card.dart';
import 'space_ai_pill.dart';

/// The story rail: reactions and SpaceAI share the top line — both are things
/// you do *to* the card on show — with the keep pill on its own line beneath,
/// where its wording has room to say what tapping it will do. Deleting stays
/// up in the header; it is the one action here you cannot undo.
class StoryFooter extends StatelessWidget {
  const StoryFooter({
    super.key,
    required this.card,
    required this.onReact,
    required this.onToggleKeep,
    this.onOpenAi,
  });

  static const _reactions = ['❤️', '😂', '😮', '😢', '🔥', '👏'];

  final SpaceCard card;
  final ValueChanged<String> onReact;
  final VoidCallback onToggleKeep;

  /// Null when SpaceAI is unavailable — the pill simply is not there.
  final VoidCallback? onOpenAi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Expanded so the pill is pushed to the far edge; the strip
              // scales down a hair on narrow screens rather than wrapping.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onOpenAi != null) ...[
                const SizedBox(width: 8),
                SpaceAiPill(onTap: onOpenAi!),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: card.kept
                ? [
                    const _Pill(label: '✦ YOU KEPT THIS', filled: true),
                    const SizedBox(width: 8),
                    _Pill(label: 'REMOVE', onTap: onToggleKeep),
                  ]
                : [_Pill(label: '✦ KEEP THIS', onTap: onToggleKeep)],
          ),
        ],
      ),
    );
  }
}

/// A rail pill. With no [onTap] it is a standing statement rather than a
/// button — "YOU KEPT THIS" reports, "REMOVE" beside it acts.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.onTap, this.filled = false});

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Text(
        label,
        style: AppTypography.mono(
            filled ? Colors.white : context.ink, 9),
      ),
    );
    final colour = filled
        ? context.colors.primary
        : context.ink.withValues(alpha: 0.07);

    if (onTap == null) {
      return Material(color: colour, shape: const StadiumBorder(), child: body);
    }
    return Material(
      color: colour,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: body,
      ),
    );
  }
}
