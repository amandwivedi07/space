import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../data/models/ai_result.dart';
import '../../data/models/ai_turn.dart';
import '../../data/repositories/space_ai_repository.dart';

/// The SpaceAI conversation: what has been asked, what came back.
class SpaceAiState {
  const SpaceAiState({
    this.mode = AiKind.draft,
    this.turns = const [],
    this.busy = false,
  });

  final AiKind mode;
  final List<AiTurn> turns;
  final bool busy;

  bool get isEmpty => turns.isEmpty;

  SpaceAiState copyWith({AiKind? mode, List<AiTurn>? turns, bool? busy}) =>
      SpaceAiState(
        mode: mode ?? this.mode,
        turns: turns ?? this.turns,
        busy: busy ?? this.busy,
      );
}

class SpaceAiViewModel extends AutoDisposeNotifier<SpaceAiState> {
  SpaceAiRepository get _repo => ref.read(spaceAiRepositoryProvider);

  @override
  SpaceAiState build() => const SpaceAiState();

  /// Switching mode keeps the thread — you might well ask for a picture of
  /// the thing you were just drafting words about.
  void setMode(AiKind mode) => state = state.copyWith(mode: mode);

  /// Opened from a card: ask on the reader's behalf, in their words, so the
  /// thread reads as a conversation from the first line.
  Future<void> beginReply(String name, String message) =>
      ask('Help me respond to $name. They said: "$message"');

  Future<void> ask(String text) async {
    final asked = text.trim();
    if (asked.isEmpty || state.busy) return;

    final prompt = _promptFor(asked);
    state = state.copyWith(
      busy: true,
      turns: [
        ...state.turns,
        AiAsk(asked),
        AiThinking(switch (state.mode) {
          AiKind.draft => AppStrings.draftIntro,
          AiKind.image => AppStrings.paintingImage,
        }),
      ],
    );

    final result = await switch (state.mode) {
      AiKind.draft => _repo.draftMessage(prompt),
      AiKind.image => _repo.generateImage(asked),
    };

    result.when(
      success: (value) => _settle(switch (value.kind) {
        AiKind.draft => AiDrafts(drafts: value.drafts, note: value.note),
        AiKind.image => AiPicture(url: value.url ?? '', prompt: asked),
      }),
      failure: (message) => _settle(AiTrouble(message)),
    );
  }

  /// Swaps the pending turn for the answer, leaving the rest of the thread be.
  void _settle(AiTurn turn) {
    final turns = [...state.turns];
    final at = turns.lastIndexWhere((t) => t is AiThinking);
    if (at >= 0) {
      turns[at] = turn;
    } else {
      turns.add(turn);
    }
    state = state.copyWith(busy: false, turns: turns);
  }

  /// A follow-up such as "shorter" means nothing on its own, so the earlier
  /// exchange rides along. Only what SpaceAI last offered is replayed — the
  /// whole history would crowd out the new instruction.
  String _promptFor(String asked) {
    if (state.mode == AiKind.image || state.turns.isEmpty) return asked;

    final firstAsk = state.turns.whereType<AiAsk>().firstOrNull;
    final lastDrafts = state.turns.whereType<AiDrafts>().lastOrNull;
    if (firstAsk == null || lastDrafts == null) return asked;

    return 'Earlier I asked: ${firstAsk.text}\n'
        'You suggested: ${lastDrafts.drafts.join(" / ")}\n'
        'Now: $asked';
  }
}

final spaceAiViewModelProvider =
    AutoDisposeNotifierProvider<SpaceAiViewModel, SpaceAiState>(
        SpaceAiViewModel.new);
