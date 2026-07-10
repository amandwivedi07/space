import 'package:flutter/material.dart';

import '../extensions/context_x.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Quiet empty state with optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.icon = Icons.auto_awesome_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: context.muted.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.display(context.ink, 20)),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              AppButton(
                  label: actionLabel!,
                  variant: AppButtonVariant.soft,
                  onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
