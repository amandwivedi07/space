import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../data/models/ai_result.dart';
import '../../data/repositories/space_ai_repository.dart';

/// State of the SpaceAI sheet.
class SpaceAiState {
  const SpaceAiState({
    this.mode = AiKind.draft,
    this.prompt = '',
    this.loading = false,
    this.stage = '',
    this.result,
    this.error,
  });

  final AiKind mode;
  final String prompt;
  final bool loading;
  final String stage; // "Painting your image…"
  final AiResult? result;
  final String? error;

  SpaceAiState copyWith({
    AiKind? mode,
    String? prompt,
    bool? loading,
    String? stage,
    AiResult? result,
    String? error,
    bool clearResult = false,
  }) =>
      SpaceAiState(
        mode: mode ?? this.mode,
        prompt: prompt ?? this.prompt,
        loading: loading ?? this.loading,
        stage: stage ?? this.stage,
        result: clearResult ? null : (result ?? this.result),
        error: error,
      );
}

class SpaceAiViewModel extends AutoDisposeNotifier<SpaceAiState> {
  SpaceAiRepository get _repo => ref.read(spaceAiRepositoryProvider);

  @override
  SpaceAiState build() => const SpaceAiState();

  void setMode(AiKind mode) =>
      state = state.copyWith(mode: mode, clearResult: true, error: null);

  void setPrompt(String prompt) => state = state.copyWith(prompt: prompt);

  Future<void> generate() async {
    final prompt = state.prompt.trim();
    if (prompt.isEmpty) return;
    state = state.copyWith(
      loading: true,
      clearResult: true,
      stage: switch (state.mode) {
        AiKind.draft => AppStrings.draftIntro,
        AiKind.image => AppStrings.paintingImage,
        AiKind.video => AppStrings.composingScene,
      },
    );

    final result = await switch (state.mode) {
      AiKind.draft => _repo.draftMessage(prompt),
      AiKind.image => _repo.generateImage(prompt),
      AiKind.video => _repo.generateVideo(prompt),
    };

    result.when(
      success: (value) =>
          state = state.copyWith(loading: false, result: value, stage: ''),
      failure: (message) =>
          state = state.copyWith(loading: false, error: message, stage: ''),
    );
  }
}

final spaceAiViewModelProvider =
    AutoDisposeNotifierProvider<SpaceAiViewModel, SpaceAiState>(
        SpaceAiViewModel.new);
