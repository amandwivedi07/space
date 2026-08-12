import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'logger_service.dart';

/// Which card is playing, and how far through it is.
class VoicePlayback {
  const VoicePlayback({
    this.cardId,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  /// The card currently loaded, or null when nothing is.
  final String? cardId;
  final bool playing;
  final Duration position;
  final Duration duration;

  /// 0..1 through the note. Falls back to 0 before the duration is known,
  /// which is the honest answer rather than a bar that jumps once it loads.
  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  bool isPlaying(String id) => playing && cardId == id;
  bool isLoaded(String id) => cardId == id;
}

/// Plays voice notes, one at a time.
///
/// A single shared player rather than one per card: two voice notes talking
/// over each other is never what someone wants, and starting a second note
/// should stop the first without the cards having to know about each other.
class VoicePlayerNotifier extends StateNotifier<VoicePlayback> {
  VoicePlayerNotifier() : super(const VoicePlayback()) {
    _player.positionStream.listen((p) {
      if (!mounted) return;
      state = VoicePlayback(
        cardId: state.cardId,
        playing: state.playing,
        position: p,
        duration: state.duration,
      );
    });
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      // Completion returns to the start rather than leaving the bar full, so
      // the card is immediately playable again.
      if (s.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
        state = VoicePlayback(
          cardId: state.cardId,
          duration: state.duration,
        );
        return;
      }
      state = VoicePlayback(
        cardId: state.cardId,
        playing: s.playing,
        position: state.position,
        duration: state.duration,
      );
    });
  }

  final AudioPlayer _player = AudioPlayer();

  /// Starts [cardId], or toggles it if it is already the loaded one.
  Future<void> toggle(String cardId, String source) async {
    try {
      if (state.cardId == cardId) {
        if (_player.playing) {
          await _player.pause();
        } else {
          await _player.play();
        }
        return;
      }

      await _player.stop();
      state = VoicePlayback(cardId: cardId);

      final duration = source.startsWith('http')
          ? await _player.setUrl(source)
          : await _player.setFilePath(source);

      if (!mounted) return;
      state = VoicePlayback(
        cardId: cardId,
        duration: duration ?? Duration.zero,
      );
      await _player.play();
    } catch (e) {
      Log.w('voice playback failed: $e');
      if (mounted) state = const VoicePlayback();
    }
  }

  /// Stops whatever is playing — used when a card fades or a room closes, so
  /// audio never outlives the card it belongs to.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    if (mounted) state = const VoicePlayback();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final voicePlayerProvider =
    StateNotifierProvider<VoicePlayerNotifier, VoicePlayback>(
  (ref) => VoicePlayerNotifier(),
);

/// True when the given path points at something on this device rather than the
/// server — a note that has been recorded but not yet uploaded.
bool isLocalAudio(String source) =>
    !source.startsWith('http') && File(source).existsSync();
