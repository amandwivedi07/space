import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../data/models/space_card.dart';

/// Instagram-style segmented progress: viewed cards full, the current one
/// drains with its fade timer, upcoming ones dim.
class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.cards,
    required this.index,
  });

  final List<SpaceCard> cards;
  final int index;

  double _fillFor(int i) {
    if (i < index) return 1;
    if (i > index) return 0;
    final card = cards[i];
    final total = card.fade.duration.inSeconds;
    final remaining = card.remaining;
    if (remaining == null || total == 0) return 1;
    return (remaining.inSeconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          for (var i = 0; i < cards.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _fillFor(i),
                    minHeight: 2.4,
                    color: context.ink.withValues(alpha: 0.85),
                    backgroundColor: context.ink.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
