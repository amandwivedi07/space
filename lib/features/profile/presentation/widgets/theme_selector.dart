import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Theme mood switch: Warm paper (light), Quiet night (dark), Match system.
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MoodTile(
            label: AppStrings.warmPaper,
            backgrounds: const [AppColors.paper],
            inks: const [AppColors.ink],
            selected: mode == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MoodTile(
            label: AppStrings.quietNight,
            backgrounds: const [AppColors.night],
            inks: const [AppColors.inkDark],
            selected: mode == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MoodTile(
            label: AppStrings.matchSystem,
            backgrounds: const [AppColors.paper, AppColors.night],
            inks: const [AppColors.ink, AppColors.inkDark],
            selected: mode == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
        ),
      ],
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.label,
    required this.backgrounds,
    required this.inks,
    required this.selected,
    required this.onTap,
  });

  /// One colour for a plain tile, two for the split "system" tile.
  final List<Color> backgrounds;
  final List<Color> inks;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final split = backgrounds.length > 1;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: split ? null : backgrounds.first,
          gradient: split
              ? LinearGradient(
                  colors: [backgrounds[0], backgrounds[0], backgrounds[1], backgrounds[1]],
                  stops: const [0, 0.5, 0.5, 1],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected ? context.ink : Colors.black.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            split
                ? Row(
                    children: [
                      Text('A', style: AppTypography.display(inks[0], 20)),
                      Text('a', style: AppTypography.display(inks[1], 20)),
                    ],
                  )
                : Text('Aa', style: AppTypography.display(inks.first, 20)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: split ? AppColors.mutedLight : inks.first,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
