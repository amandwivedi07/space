import 'package:flutter/material.dart';

import '../extensions/context_x.dart';

/// Soft paper card — the base surface for message cards, tiles and panels.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
    this.onLongPress,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: context.ink.withValues(alpha: 0.05)),
    );

    return Material(
      color: color ?? context.colors.surface,
      shape: shape,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: shape,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
