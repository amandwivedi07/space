import 'package:flutter/material.dart';

import '../../../../core/constants/palettes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/ai_result.dart';

/// The generated picture, shown before you decide whether to send it.
class AiMediaPreview extends StatelessWidget {
  const AiMediaPreview({super.key, required this.result, required this.onSend});

  final AiResult result;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final url = result.url ?? '';

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.network(
                url,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const _Placeholder(),
                errorBuilder: (_, _, _) =>
                    const _Placeholder(label: "Couldn't load that picture"),
              ),
              // A scrim, so the prompt stays readable over a bright image.
              Container(
                height: 96,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  result.prompt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                      Colors.white.withValues(alpha: 0.94), 17),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: 'Send the image',
          expanded: true,
          onPressed: onSend,
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Container(
        height: 240,
        width: double.infinity,
        color: SpacePalette.ember.to.withValues(alpha: 0.18),
        alignment: Alignment.center,
        child: label == null
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label!),
      );
}
