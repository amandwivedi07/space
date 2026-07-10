import 'package:flutter/material.dart';

import '../extensions/context_x.dart';
import '../theme/app_typography.dart';

/// Calm loading state — a soft pulsing dot with an optional whisper of copy.
class AppLoading extends StatefulWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.25, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.ink.withValues(alpha: 0.7),
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(widget.message!,
                style: AppTypography.display(context.muted, 16)),
          ],
        ],
      ),
    );
  }
}
