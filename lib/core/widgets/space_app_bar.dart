import 'package:flutter/material.dart';

import '../extensions/context_x.dart';
import '../theme/app_typography.dart';

/// App bar with the Space voice: small mono eyebrow + italic display title.
class SpaceAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SpaceAppBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions,
    this.leading,
    this.onBack,
  });

  final String title;
  final String? eyebrow;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      leading: leading ??
          (onBack == null
              ? null
              : IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                )),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (eyebrow != null)
            Text(eyebrow!.toUpperCase(),
                style: AppTypography.mono(context.muted, 9)),
          Text(title,
              style: AppTypography.display(context.ink, 21),
              overflow: TextOverflow.ellipsis),
        ],
      ),
      actions: actions,
    );
  }
}
