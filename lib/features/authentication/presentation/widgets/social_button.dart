import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';

/// The wide "Continue with …" buttons on the sign-in screen. Solid light
/// surface on the dark hero, with a leading brand mark.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconWidget,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    const radius = 16.0;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black54),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iconWidget != null)
                        iconWidget!
                      else if (icon != null)
                        Icon(icon, size: 20, color: Colors.black87),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: context.text.titleSmall?.copyWith(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Google's "G" drawn as text so no network asset is needed.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4285F4),
        height: 1.1,
      ),
    );
  }
}
