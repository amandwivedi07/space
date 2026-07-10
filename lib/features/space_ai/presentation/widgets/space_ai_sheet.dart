import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/ai_result.dart';
import '../viewmodels/space_ai_viewmodel.dart';
import 'ai_draft_list.dart';
import 'ai_media_preview.dart';

/// What the sheet hands back to the composer.
sealed class AiOutcome {
  const AiOutcome();
}

class AiDraftChosen extends AiOutcome {
  const AiDraftChosen(this.text);
  final String text;
}

class AiMediaReady extends AiOutcome {
  const AiMediaReady(this.kind, this.prompt, this.seed);
  final AiKind kind;
  final String prompt;
  final int seed;
}

/// The SpaceAI sheet: write with me, an image of…, a moving moment of….
class SpaceAiSheet extends ConsumerWidget {
  const SpaceAiSheet({super.key});

  static Future<AiOutcome?> show(BuildContext context) =>
      AppBottomSheet.show<AiOutcome>(
        context,
        eyebrow: AppStrings.spaceAi,
        title: AppStrings.whatToSay,
        child: const SpaceAiSheet(),
      );

  static const _promptChips = [
    'Apologize for being distant',
    'Wish them goodnight',
    "Tell them I'm proud of them",
    'Plan a surprise weekend',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spaceAiViewModelProvider);
    final vm = ref.read(spaceAiViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          AppChip(
            label: AppStrings.writeWithAi,
            selected: state.mode == AiKind.draft,
            onTap: () => vm.setMode(AiKind.draft),
          ),
          const SizedBox(width: 8),
          AppChip(
            label: 'Image',
            selected: state.mode == AiKind.image,
            onTap: () => vm.setMode(AiKind.image),
          ),
          const SizedBox(width: 8),
          AppChip(
            label: 'Video',
            selected: state.mode == AiKind.video,
            onTap: () => vm.setMode(AiKind.video),
          ),
        ]),
        const SizedBox(height: 16),
        AppTextField(
          hint: switch (state.mode) {
            AiKind.draft => AppStrings.whatToSay,
            AiKind.image => AppStrings.describeImage,
            AiKind.video => AppStrings.describeMoment,
          },
          onChanged: vm.setPrompt,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (state.mode == AiKind.draft) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in _promptChips)
                AppChip(
                    label: chip,
                    onTap: () {
                      vm.setPrompt(chip);
                      vm.generate();
                    }),
            ],
          ),
        ],
        const SizedBox(height: 18),
        if (state.loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: AppLoading(message: state.stage),
          )
        else if (state.error != null)
          Text(state.error!,
              style:
                  context.text.bodySmall?.copyWith(color: context.colors.error))
        else if (state.result != null)
          _ResultView(result: state.result!),
        const SizedBox(height: 16),
        AppButton(
          label: state.result == null ? 'Bring it to life' : 'Try once more',
          expanded: true,
          busy: state.loading,
          variant: AppButtonVariant.soft,
          onPressed: vm.generate,
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final AiResult result;

  @override
  Widget build(BuildContext context) {
    if (result.kind == AiKind.draft) {
      return AiDraftList(
        drafts: result.drafts,
        onChoose: (text) => Navigator.of(context).pop(AiDraftChosen(text)),
      );
    }
    return AiMediaPreview(
      result: result,
      onSend: () => Navigator.of(context)
          .pop(AiMediaReady(result.kind, result.prompt, result.seed)),
    );
  }
}
