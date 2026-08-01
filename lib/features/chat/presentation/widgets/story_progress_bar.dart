import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../data/models/space_card.dart';

/// Instagram-style segmented progress: viewed cards full, the current one
/// fills as its fade elapses, upcoming ones dim.
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
    // A kept card, or one whose clock has not started, has no elapsed time to
    // show — a full bar reads as "this one is not going anywhere".
    if (remaining == null || total == 0) return 1;
    // Elapsed, not remaining: the bar travels forward as the card runs out,
    // the way a story segment does.
    return (1 - remaining.inSeconds / total).clamp(0.0, 1.0);
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
