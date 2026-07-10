import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Small ember-coloured unread count pill.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ember,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: Theme.of(context).colorScheme.surface, width: 1.5),
      ),
      child: Text(
        '$count',
        style: AppTypography.mono(Colors.white, 10)
            .copyWith(letterSpacing: 0, fontWeight: FontWeight.w600),
      ),
    );
  }
}
