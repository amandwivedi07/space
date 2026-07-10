import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_card.dart';

/// Three draft variants — tap one to use it.
class AiDraftList extends StatelessWidget {
  const AiDraftList({super.key, required this.drafts, required this.onChoose});

  final List<String> drafts;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final draft in drafts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: () => onChoose(draft),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                      child:
                          Text(draft, style: context.text.bodyMedium)),
                  const SizedBox(width: 8),
                  Icon(Icons.north_east_rounded,
                      size: 14, color: context.muted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
