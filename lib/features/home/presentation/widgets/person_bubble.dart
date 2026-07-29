import 'package:flutter/material.dart';

import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/presence_dot.dart';
import '../../../../core/widgets/unread_badge.dart';
import '../../data/models/person.dart';

/// One drifting person bubble on the cluster.
class PersonBubble extends StatelessWidget {
  const PersonBubble({
    super.key,
    required this.person,
    required this.onTap,
    this.size,
  });

  final Person person;
  final VoidCallback onTap;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? person.bubbleSize;
    return Semantics(
      button: true,
      label: 'Open space with ${person.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: person.pending ? 0.55 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppAvatar(
                    name: person.name,
                    palette: SpacePalette.byId(person.paletteId),
                    avatarUrl: person.avatarUrl,
                    size: size,
                  ),
                  Positioned(
                    right: size * 0.04,
                    bottom: size * 0.04,
                    child: PresenceDot(
                        presence: person.presence, size: size * 0.14 + 4),
                  ),
                  if (person.unread > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: UnreadBadge(count: person.unread),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                person.name,
                style: context.text.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500, color: context.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
