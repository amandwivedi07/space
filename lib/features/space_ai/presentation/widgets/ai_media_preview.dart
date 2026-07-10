import 'package:flutter/material.dart';

import '../../../../core/constants/palettes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/ai_result.dart';

/// Preview of generated media (mock: deterministic gradient scene).
class AiMediaPreview extends StatelessWidget {
  const AiMediaPreview({super.key, required this.result, required this.onSend});

  final AiResult result;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final palette = SpacePalette.all[result.seed % SpacePalette.all.length];
    final partner =
        SpacePalette.all[(result.seed + 2) % SpacePalette.all.length];

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.from, palette.to, partner.to],
              ),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(14),
            child: Text(
              result.prompt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(
                  Colors.white.withValues(alpha: 0.94), 17),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: result.kind == AiKind.video
              ? 'Send the moment'
              : 'Send the image',
          expanded: true,
          onPressed: onSend,
        ),
      ],
    );
  }
}
