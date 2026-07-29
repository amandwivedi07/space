import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';

/// Three draft variants, styled like the web app: dark pills with italic
/// serif copy and a "SEND →" affordance. Tapping SENDS the card directly.
class AiDraftList extends StatelessWidget {
  const AiDraftList({super.key, required this.drafts, required this.onChoose});

  final List<String> drafts;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final onInk = context.theme.scaffoldBackgroundColor;
    return Column(
      children: [
        for (final draft in drafts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: context.ink,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () => onChoose(draft),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(draft, style: AppTypography.display(onInk, 16)),
                      const SizedBox(height: 8),
                      Text('SEND →',
                          style: AppTypography.mono(
                              onInk.withValues(alpha: 0.65), 9)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
