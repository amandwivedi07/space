import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../chat/data/models/space_card.dart';
import '../../../chat/presentation/widgets/card_content.dart';

/// One keepsake: an index in the corner, the card exactly as it arrived, and
/// who kept it, when. Alternating tilt keeps the shelf feeling hand-placed.
class KeepsakeCard extends StatelessWidget {
  const KeepsakeCard({
    super.key,
    required this.card,
    required this.index,
    required this.total,
    required this.onTap,
    this.onLongPress,
    this.onMenu,
    this.senderName,
    this.senderAvatarUrl = '',
    this.senderPaletteId = 'ember',
  });

  final SpaceCard card;
  final int index; // zero-based position on the shelf
  final int total;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Opens the keepsake's actions. Null inside the actions sheet itself.
  final VoidCallback? onMenu;
  final String? senderName;
  final String senderAvatarUrl;
  final String senderPaletteId;

  static const _monthNames = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  String get _typeLabel => switch (card.type) {
        CardType.text => 'NOTE',
        CardType.photo => 'PHOTO',
        CardType.video => 'CLIP',
        CardType.voice => 'VOICE',
        CardType.link => 'LINK',
        CardType.file => 'FILE',
        CardType.aiImage => 'IMAGE',
        CardType.aiVideo => 'CLIP',
      };

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _keptStamp {
    final at = card.keptAt;
    if (at == null) return 'KEPT';
    return 'KEPT · ${at.day} ${_monthNames[at.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final name = senderName ?? (card.isMine ? 'You' : 'Them');

    return Transform.rotate(
      // A whisper of tilt, alternating, like cards laid down by hand.
      angle: (index.isEven ? -1 : 1) * 0.008,
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.muted.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('✦ ${_two(index + 1)} / ${_two(total)}',
                        style: AppTypography.mono(context.muted, 9)),
                    const Spacer(),
                    Text(_typeLabel,
                        style: AppTypography.mono(context.muted, 9)),
                    if (onMenu != null) ...[
                      const SizedBox(width: 6),
                      // Visible on purpose: a long-press-only affordance is
                      // one nobody finds.
                      InkWell(
                        onTap: onMenu,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.more_horiz_rounded,
                              size: 17, color: context.muted),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                CardContent(card: card),
                const SizedBox(height: 14),
                Row(
                  children: [
                    AppAvatar(
                      name: name,
                      palette: SpacePalette.byId(senderPaletteId),
                      avatarUrl: senderAvatarUrl,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: AppTypography.display(context.ink, 13)
                                .copyWith(fontStyle: FontStyle.italic)),
                        Text(_keptStamp,
                            style: AppTypography.mono(context.muted, 8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
