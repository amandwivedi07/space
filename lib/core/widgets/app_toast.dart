import 'package:flutter/material.dart';

/// Floating toast/snackbar helper — one voice for transient feedback.
class AppToast {
  AppToast._();

  static void show(BuildContext context, String message, {IconData? icon}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
