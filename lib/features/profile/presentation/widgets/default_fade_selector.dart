import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/fade_options.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_chip.dart';

/// Default fade timer for every new card.
class DefaultFadeSelector extends StatelessWidget {
  const DefaultFadeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final FadeOption selected;
  final ValueChanged<FadeOption> onChanged;

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
                onTap: () => onChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(AppStrings.changePerCard, style: context.text.bodySmall),
      ],
    );
  }
}
