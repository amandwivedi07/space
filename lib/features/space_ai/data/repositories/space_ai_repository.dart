import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../models/ai_result.dart';

/// SpaceAI contract — one seam for the future model API.
abstract class SpaceAiRepository {
  Future<Result<AiResult>> draftMessage(String prompt);
  Future<Result<AiResult>> generateImage(String prompt, {String? referencePath});
  Future<Result<AiResult>> generateVideo(String prompt);
}

/// Staged mock: waits like a model would, then answers in the Space voice.
class MockSpaceAiRepository implements SpaceAiRepository {
  final _random = Random();

  Future<void> _think() => Future.delayed(AppConstants.mockAiDelay);

  @override
  Future<Result<AiResult>> draftMessage(String prompt) async {
    await _think();
    final theme = prompt.trim().isEmpty ? 'what you mean' : prompt.trim();
    return Success(AiResult(
      kind: AiKind.draft,
      prompt: prompt,
      drafts: [
        "I keep circling around $theme — here it is, plainly: I'm glad it's you.",
        "No preamble. $theme, and I mean every word of it.",
        "If I say this quietly, will you hear it better? $theme.",
      ],
    ));
  }

  @override
  Future<Result<AiResult>> generateImage(String prompt,
      {String? referencePath}) async {
    await _think();
    // Real API later: POST /ai/image {prompt, reference} → url.
    return Success(AiResult(
        kind: AiKind.image, prompt: prompt, seed: _random.nextInt(1000)));
  }

  @override
  Future<Result<AiResult>> generateVideo(String prompt) async {
    await _think();
    return Success(AiResult(
        kind: AiKind.video, prompt: prompt, seed: _random.nextInt(1000)));
  }
}

final spaceAiRepositoryProvider =
    Provider<SpaceAiRepository>((ref) => MockSpaceAiRepository());
