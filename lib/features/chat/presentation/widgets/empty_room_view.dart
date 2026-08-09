import 'package:flutter/material.dart';

import '../../../../core/constants/fade_options.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/constants/presence.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/presence_dot.dart';

/// The web app's beautiful first-moment screen: glowing avatar, "A NEW SPACE
/// WITH", the fade promise, and a Create-with-SpaceAI tile.
class EmptyRoomView extends StatelessWidget {
  const EmptyRoomView({
    super.key,
    required this.name,
    required this.paletteId,
    required this.presence,
    required this.fade,
    this.onOpenAi,
    this.avatarUrl,
    this.photoPath,
  });

  final String name;
  final String paletteId;
  final Presence presence;
  final FadeOption fade;

  /// The other person's own picture — falls back to their initial when
  /// there is none, same as everywhere else AppAvatar is used.
  final String? avatarUrl;
  final String? photoPath;
  /// Null when SpaceAI is switched off server-side — the tile is then
  /// hidden rather than shown and failing.
  final VoidCallback? onOpenAi;

  String get _fadeSentence => switch (fade) {
        FadeOption.viewOnce => 'It shows once, then it is gone.',
        FadeOption.afterSeen => 'It fades the moment they see it.',
        _ => 'It fades ${fade.label} after they see it.',
      };

  @override
  Widget build(BuildContext context) {
    final palette = SpacePalette.byId(paletteId);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.to.withValues(alpha: 0.45),
                        blurRadius: 70,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: AppAvatar(
                    name: name,
                    palette: palette,
                    avatarUrl: avatarUrl,
                    photoPath: photoPath,
                    size: 128,
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: PresenceDot(presence: presence, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Text('A NEW SPACE WITH',
                style: AppTypography.mono(context.muted, 10)),
            const SizedBox(height: 8),
            Text(name,
                textAlign: TextAlign.center,
                style: AppTypography.display(context.ink, 42)),
            const SizedBox(height: 18),
            Container(
                width: 48, height: 1, color: context.ink.withValues(alpha: 0.2)),
            const SizedBox(height: 22),
            Text(
              'Say the first thing.\n$_fadeSentence',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                  context.ink.withValues(alpha: 0.85), 22),
            ),
            const SizedBox(height: 34),
            Text('CREATE WITH', style: AppTypography.mono(context.muted, 9)),
            const SizedBox(height: 12),
            if (onOpenAi case final open?) _SpaceAiTile(onTap: open),
            const SizedBox(height: 36),
            Text(
              'CARDS ${fade.roomClause} · KEEP TO REMEMBER',
              textAlign: TextAlign.center,
              style: AppTypography.mono(
                  context.muted.withValues(alpha: 0.8), 8.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceAiTile extends StatelessWidget {
  const _SpaceAiTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.ink,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
                child: Icon(Icons.auto_awesome,
                    size: 20, color: context.theme.scaffoldBackgroundColor),
              ),
              const SizedBox(height: 10),
              Text(
                'SpaceAI',
                style: AppTypography.display(
                    context.theme.scaffoldBackgroundColor, 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
