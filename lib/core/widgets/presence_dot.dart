import 'package:flutter/material.dart';

import '../constants/presence.dart';
import '../theme/app_colors.dart';

extension PresenceColorX on Presence {
  Color get color => switch (this) {
        Presence.here => AppColors.presenceHere,
        Presence.recent => AppColors.presenceRecent,
        Presence.away => AppColors.presenceAway,
      };
}

/// Small presence indicator, glowing softly when someone is here.
class PresenceDot extends StatelessWidget {
  const PresenceDot({super.key, required this.presence, this.size = 10});

  final Presence presence;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: presence.color,
        border: Border.all(
            color: Theme.of(context).colorScheme.surface, width: 1.5),
        boxShadow: presence == Presence.here
            ? [
                BoxShadow(
                    color: presence.color.withValues(alpha: 0.5),
                    blurRadius: 6)
              ]
            : null,
      ),
    );
  }
}
