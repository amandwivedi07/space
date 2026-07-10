import 'package:flutter/material.dart';

import '../extensions/context_x.dart';
import '../theme/app_typography.dart';

/// Standard modal bottom sheet chrome: grab handle, eyebrow, display title.
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    String? eyebrow,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: ctx.viewInsets.bottom),
        child: _SheetScaffold(title: title, eyebrow: eyebrow, child: child),
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.child, this.title, this.eyebrow});

  final Widget child;
  final String? title;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (eyebrow != null) ...[
              const SizedBox(height: 18),
              Text(eyebrow!.toUpperCase(),
                  style: AppTypography.mono(context.muted, 10)),
            ],
            if (title != null) ...[
              const SizedBox(height: 8),
              Text(title!, style: AppTypography.display(context.ink, 22)),
            ],
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}
