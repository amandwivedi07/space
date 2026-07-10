import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/space_card.dart';
import 'card_content.dart';

/// The current card, fullscreen story-style: a paper speech bubble drifting
/// on the dark room — big italic serif for text, framed content for media.
class StoryCardView extends StatelessWidget {
  const StoryCardView({super.key, required this.card});

  final SpaceCard card;

  bool get _veiled => card.isViewOnce && card.consumedAt == null;

  double _fontSize(String text) {
    if (text.length <= 12) return 44;
    if (text.length <= 40) return 32;
    if (text.length <= 120) return 24;
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    final alignment =
        card.isMine ? Alignment.centerRight : Alignment.centerLeft;

    final Widget body;
    if (_veiled) {
      body = const _ViewOnceVeil();
    } else if (card.type == CardType.text) {
      body = Text(
        card.body,
        style: AppTypography.display(context.ink, _fontSize(card.body)),
      );
    } else {
      // Media/voice/link render with their own chrome inside the bubble.
      body = CardContent(card: card);
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border.all(color: context.ink.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(28),
                topRight: const Radius.circular(28),
                bottomLeft: Radius.circular(card.isMine ? 28 : 6),
                bottomRight: Radius.circular(card.isMine ? 6 : 28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: context.isDark ? 0.45 : 0.14),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}

class _ViewOnceVeil extends StatelessWidget {
  const _ViewOnceVeil();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.visibility_outlined, size: 24, color: context.ink),
        const SizedBox(height: 10),
        Text('Tap to view once',
            style: AppTypography.display(context.ink, 22)),
        const SizedBox(height: 4),
        Text(AppStrings.viewOnceThenGone,
            style: TextStyle(fontSize: 12, color: context.muted)),
      ],
    );
  }
}
