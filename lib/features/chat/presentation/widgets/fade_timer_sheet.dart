import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/fade_options.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_chip.dart';

/// Picker for a card's fade timer. Returns the chosen option.
class FadeTimerSheet extends StatelessWidget {
  const FadeTimerSheet({super.key, required this.selected});

  final FadeOption selected;

  static Future<FadeOption?> show(BuildContext context, FadeOption selected) =>
      AppBottomSheet.show<FadeOption>(
        context,
        eyebrow: 'Fade timer',
        title: 'How long should it linger?',
        child: FadeTimerSheet(selected: selected),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in FadeOption.values)
              AppChip(
                label: option.label,
                selected: option == selected,
                icon: option.isViewOnce
                    ? Icons.visibility_outlined
                    : option == FadeOption.afterSeen
                        ? Icons.blur_on_rounded
                        : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(AppStrings.changePerCard, style: context.text.bodySmall),
      ],
    );
  }
}
