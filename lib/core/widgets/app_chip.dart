import 'package:flutter/material.dart';

import '../extensions/context_x.dart';

/// Selectable pill chip — fade timers, AI prompts, palette labels.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = context.ink;
    return Material(
      color: selected ? ink : ink.withValues(alpha: 0.05),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 14,
                    color: selected
                        ? context.theme.scaffoldBackgroundColor
                        : ink),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: context.text.bodySmall?.copyWith(
                  color: selected
                      ? context.theme.scaffoldBackgroundColor
                      : ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
