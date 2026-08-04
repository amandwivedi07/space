import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

/// The "✦ SPACEAI" pill: violet-to-blue like the brand mark, with a slow
/// sheen sweeping across so it reads as alive without shouting. It sits in
/// the story rail, so it carries no caption — one row, no stacking.
class SpaceAiPill extends StatefulWidget {
  const SpaceAiPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<SpaceAiPill> createState() => _SpaceAiPillState();
}

class _SpaceAiPillState extends State<SpaceAiPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _sheen,
        builder: (context, child) {
          // The highlight travels from off-screen left to off-screen
          // right; most of the cycle it is out of view, so the pill
          // glints rather than strobes.
          final t = _sheen.value * 4 - 1.5;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFFC79BEF), Color(0xFF6FA8F5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8F7BF3).withValues(alpha: 0.45),
                  blurRadius: 26,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment(t - 0.6, -0.4),
                end: Alignment(t + 0.6, 0.4),
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            const SizedBox(width: 7),
            Text('SPACEAI',
                style: AppTypography.mono(Colors.white, 11)
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
