import 'package:flutter/material.dart';

import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../data/models/space_card.dart';

/// Photo / video / AI-generated media body of a card.
class MediaCardContent extends StatelessWidget {
  const MediaCardContent({super.key, required this.card});

  final SpaceCard card;

  bool get _isVideo =>
      card.type == CardType.video || card.type == CardType.aiVideo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (card.mediaPath != null)
                AppNetworkImage(
                    source: card.mediaPath!, height: 190, width: 260)
              else
                _GeneratedArt(seed: card.aiSeed, prompt: card.body),
              if (_isVideo)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 26),
                ),
              if (card.aiGenerated)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('✦ GENERATED',
                        style: AppTypography.mono(Colors.white, 8)),
                  ),
                ),
            ],
          ),
        ),
        if (card.body.isNotEmpty && card.mediaPath != null) ...[
          const SizedBox(height: 8),
          Text(card.body, style: context.text.bodyMedium),
        ],
      ],
    );
  }
}

/// Mock AI media: a deterministic gradient scene with the prompt as caption.
class _GeneratedArt extends StatelessWidget {
  const _GeneratedArt({required this.seed, required this.prompt});

  final int seed;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final palette = SpacePalette.all[seed % SpacePalette.all.length];
    final partner = SpacePalette.all[(seed + 2) % SpacePalette.all.length];
    return Container(
      height: 190,
      width: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.from, palette.to, partner.to],
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(12),
      child: Text(
        prompt,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.display(Colors.white.withValues(alpha: 0.92), 15),
      ),
    );
  }
}
