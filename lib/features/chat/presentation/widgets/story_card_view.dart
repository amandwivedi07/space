import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/space_card.dart';
import 'card_content.dart';
import 'full_bleed_link.dart';
import 'media_card_content.dart';

/// The current card, fullscreen story-style: a paper speech bubble drifting
/// on the dark room — big italic serif for text, framed content for media.
class StoryCardView extends ConsumerWidget {
  const StoryCardView({super.key, required this.card});

  final SpaceCard card;

  bool get _veiled => card.isViewOnce && card.consumedAt == null;

  double _fontSize(String text) {
    if (text.length <= 12) return 44;
    if (text.length <= 40) return 32;
    if (text.length <= 120) return 24;
    return 18;
  }

  bool get _isMedia => switch (card.type) {
        CardType.photo ||
        CardType.video ||
        CardType.aiImage ||
        CardType.aiVideo =>
          true,
        _ => false,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A shared link with a picture of its own gets the same treatment as a
    // photo: the page fills the stage, its title over a scrim.
    if (!_veiled) {
      final preview = fullBleedLinkPreview(ref, card);
      if (preview != null) {
        return FullBleedLink(card: card, preview: preview);
      }
    }

    // A picture is the message. Boxing it in a bubble makes it a thumbnail,
    // so media takes the whole stage and the chrome floats on top of it.
    if (_isMedia && !_veiled) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FullBleedMedia(card: card),
          if (card.reactions.isNotEmpty)
            Positioned(
              right: 20,
              bottom: 22,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  card.reactions.take(8).join(' '),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
        ],
      );
    }

    final alignment =
        card.isMine ? Alignment.centerRight : Alignment.centerLeft;

    final Widget body;
    if (_veiled) {
      body = const _ViewOnceVeil();
    } else if (card.type == CardType.text) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.body,
            style: AppTypography.display(context.ink, _fontSize(card.body)),
          ),
          if (card.aiGenerated) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(AppStrings.sentWithAi,
                  style: AppTypography.mono(context.muted, 8)),
            ),
          ],
        ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: card.isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
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
              if (card.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: context.ink.withValues(alpha: 0.06)),
                    ),
                    child: Text(
                      card.reactions.take(8).join(' '),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
            ],
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
