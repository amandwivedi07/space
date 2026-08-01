import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../extensions/context_x.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// The one dialog component for the whole app — every confirmation and
/// alert goes through here so they all speak with the same voice.
class AppDialog {
  AppDialog._();

  /// A single-button notice: something happened, nothing to decide.
  static Future<void> alert(
    BuildContext context, {
    required String title,
    String? body,
    String buttonLabel = 'Okay',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.display(ctx.ink, 20)),
              if (body != null) ...[
                const SizedBox(height: 10),
                Text(body, style: ctx.text.bodyMedium),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: buttonLabel,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? body,
    String confirmLabel = 'Confirm',
    String cancelLabel = AppStrings.cancel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.display(ctx.ink, 20)),
              if (body != null) ...[
                const SizedBox(height: 10),
                Text(body, style: ctx.text.bodyMedium),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: confirmLabel,
                    variant: destructive
                        ? AppButtonVariant.danger
                        : AppButtonVariant.filled,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
