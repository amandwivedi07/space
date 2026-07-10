import 'package:flutter/material.dart';

import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/unread_badge.dart';
import '../../data/models/circle_space.dart';
import '../../data/models/person.dart';

/// A circle (group) bubble — overlapping member avatars in a soft ring.
class CircleBubble extends StatelessWidget {
  const CircleBubble({
    super.key,
    required this.circle,
    required this.members,
    required this.onTap,
    this.size,
  });

  final CircleSpace circle;
  final List<Person> members;
  final VoidCallback onTap;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? circle.bubbleSize;
    return Semantics(
      button: true,
      label: 'Open ${circle.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  padding: EdgeInsets.all(size * 0.12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.surface,
                    border: Border.all(
                        color: context.ink.withValues(alpha: 0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: size / 6,
                        offset: Offset(0, size / 16),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: AvatarStack(
                    names: members.map((m) => m.name).toList(),
                    palettes: members
                        .map((m) => SpacePalette.byId(m.paletteId))
                        .toList(),
                    size: size * 0.34,
                  ),
                ),
                if (circle.unread > 0)
                  Positioned(
                      top: -2,
                      right: -2,
                      child: UnreadBadge(count: circle.unread)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              circle.name,
              style: context.text.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500, color: context.ink),
            ),
          ],
        ),
      ),
    );
  }
}
