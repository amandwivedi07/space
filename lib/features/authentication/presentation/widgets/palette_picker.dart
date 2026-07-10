import 'package:flutter/material.dart';

import '../../../../core/constants/palettes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';

/// Row of the six Space gradient palettes with a selected ring.
class PalettePicker extends StatelessWidget {
  const PalettePicker({
    super.key,
    required this.selectedId,
    required this.onSelect,
    this.label = 'Palette',
  });

  final String selectedId;
  final ValueChanged<String> onSelect;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(),
              style: AppTypography.mono(context.muted, 10)),
          const SizedBox(height: 10),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final palette in SpacePalette.all)
              GestureDetector(
                onTap: () => onSelect(palette.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: palette.gradient,
                    border: Border.all(
                      color: selectedId == palette.id
                          ? context.ink
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
