import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import 'empty_state.dart';

/// Error state wrapper — same layout as EmptyState with retry affordance.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: AppStrings.somethingWentWrong,
      body: message,
      actionLabel: onRetry == null ? null : AppStrings.tryAgain,
      onAction: onRetry,
    );
  }
}
