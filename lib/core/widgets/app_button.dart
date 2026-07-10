import 'package:flutter/material.dart';

import '../extensions/context_x.dart';

enum AppButtonVariant { filled, soft, ghost, danger }

/// The one button used everywhere. Pill-shaped, calm, with a busy state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.busy = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool busy;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final ink = context.ink;
    final (bg, fg) = switch (variant) {
      AppButtonVariant.filled => (ink, context.theme.scaffoldBackgroundColor),
      AppButtonVariant.soft => (ink.withValues(alpha: 0.06), ink),
      AppButtonVariant.ghost => (Colors.transparent, ink),
      AppButtonVariant.danger => (context.colors.error, Colors.white),
    };

    final child = busy
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: context.text.labelLarge?.copyWith(color: fg)),
            ],
          );

    final button = TextButton(
      onPressed: busy ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: onPressed == null && !busy
            ? bg.withValues(alpha: 0.35)
            : bg,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: const StadiumBorder(),
      ),
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
