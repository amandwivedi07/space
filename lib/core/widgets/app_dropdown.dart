import 'package:flutter/material.dart';

import '../extensions/context_x.dart';
import '../theme/app_typography.dart';

/// Styled dropdown consistent with the input theme.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    this.onChanged,
    this.label,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(),
              style: AppTypography.mono(context.muted, 10)),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(labelOf(item), style: context.text.bodyMedium),
              ),
          ],
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(Icons.expand_more_rounded, size: 18, color: context.muted),
        ),
      ],
    );
  }
}
