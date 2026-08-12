import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:stt_record/stt_record.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/services/audio_recorder_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Tap-to-record mic — first tap starts, second tap stops and sends.
///
/// iOS uses [SttRecord] (one mic session for audio + transcript). Android uses
/// the file recorder plus speech-to-text.
class VoiceRecordButton extends ConsumerStatefulWidget {
  const VoiceRecordButton({
    super.key,
    required this.onRecorded,
    this.onStateChanged,
  });

  /// (path to the recorded file, duration in seconds, transcript)
  final void Function(String path, int seconds, String transcript) onRecorded;

  /// Live recording state for the composer preview above the input bar.
  final void Function(bool recording, int elapsedSec, String transcript)?
      onStateChanged;

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton> {
  static final SpeechToText _sharedSpeech = SpeechToText();
  static bool _speechInitialized = false;

  final SttRecord _sttRecord = SttRecord();
  StreamSubscription<SttRecordTranscript>? _transcriptSub;

  Timer? _ticker;
  int _elapsed = 0;
  bool _recording = false;
  bool _starting = false;
  bool _speechListening = false;
  String _transcript = '';

  /// Both mobile platforms, not just iOS.
  ///
  /// The Android path used to run the file recorder and speech_to_text side by
  /// side, which opens the microphone twice. On a real device the recogniser
  /// still ran to completion but received silence, so every voice note arrived
  /// with an empty transcript — the logs showed AudioRecord sessions for both
  /// com.talkinspace.talkinspace and the recogniser overlapping, and the
  /// recogniser ending on MIC_END_OF_DATA with an empty hypothesis.
  ///
  /// SttRecord runs one AudioRecord and feeds both the recogniser and the
  /// file, so there is nothing to contend over. It writes WAV, which POST
  /// /media already accepts.
  bool get _useSttRecord => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  void _notifyState() =>
      widget.onStateChanged?.call(_recording, _elapsed, _transcript);

  Future<bool> _ensureSpeech() async {
    if (_speechInitialized) return true;
    try {
      _speechInitialized = await _sharedSpeech.initialize(
        onStatus: (_) {},
        onError: (error) => Log.w('speech error: ${error.errorMsg}'),
      );
    } catch (e) {
      Log.w('speech init failed: $e');
      _speechInitialized = false;
    }
    return _speechInitialized;
  }

  Future<void> _beginSpeech() async {
    if (!await _ensureSpeech()) return;
    try {
      _speechListening = true;
      await _sharedSpeech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _transcript = result.recognizedWords);
          _notifyState();
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
        ),
      );
    } catch (e) {
      Log.w('speech listen failed: $e');
      _speechListening = false;
    }
  }

  Future<void> _endSpeech() async {
    if (!_speechListening) return;
    try {
      await _sharedSpeech.stop();
    } catch (e) {
      Log.w('speech stop failed: $e');
    }
    _speechListening = false;
  }

  Future<void> _start() async {
    if (_starting || _recording) return;
    _starting = true;
    _transcript = '';

    try {
      if (_useSttRecord) {
        if (!await _sttRecord.requestPermission()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone unavailable')),
            );
          }
          return;
        }

        _transcriptSub = _sttRecord.transcripts.listen((event) {
          if (!mounted || event.text.isEmpty) return;
          setState(() => _transcript = event.text);
          _notifyState();
        });

        await _sttRecord.start(
          localeId: 'en-US',
          partialResults: true,
        );
      } else {
        final started = await ref.read(audioRecorderProvider).start();
        if (!started) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone unavailable')),
            );
          }
          return;
        }
        await _beginSpeech();
      }

      if (!mounted) return;
      setState(() {
        _recording = true;
        _elapsed = 0;
      });
      _notifyState();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _elapsed++);
          _notifyState();
        }
      });
    } catch (e) {
      Log.w('voice start failed: $e');
      await _cleanupWithoutSend();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start recording')),
        );
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> _cleanupWithoutSend() async {
    _ticker?.cancel();
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    if (_useSttRecord) {
      try {
        await _sttRecord.cancel();
      } catch (_) {}
    } else {
      await _endSpeech();
      try {
        await ref.read(audioRecorderProvider).cancel();
      } catch (_) {}
    }
    if (mounted) setState(() => _recording = false);
    _notifyState();
  }

  Future<void> _stopAndSend() async {
    if (!_recording && !_starting) return;
    _ticker?.cancel();
    final seconds = _elapsed.clamp(1, 120);
    if (mounted) setState(() => _recording = false);

    String? path;
    try {
      if (_useSttRecord) {
        await _transcriptSub?.cancel();
        _transcriptSub = null;
        final result = await _sttRecord.stop();
        path = result.audioPath;
      } else {
        await _endSpeech();
        path = await ref.read(audioRecorderProvider).stop();
      }
    } catch (e) {
      Log.w('voice stop failed: $e');
    }

    _notifyState();
    if (path != null && path.isNotEmpty) {
      widget.onRecorded(path, seconds, _transcript.trim());
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That voice note was too short')),
      );
    }
  }

  void _onTap() {
    if (_recording) {
      _stopAndSend();
    } else if (!_starting) {
      _start();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _transcriptSub?.cancel();
    if (_recording) {
      if (_useSttRecord) {
        _sttRecord.cancel();
      } else {
        _endSpeech();
        ref.read(audioRecorderProvider).cancel();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _recording ? AppStrings.tapToSend : AppStrings.tapToSpeak,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _recording
                ? AppColors.danger
                : context.ink.withValues(alpha: 0.06),
          ),
          child: Icon(
            Icons.mic_none_rounded,
            size: 20,
            color: _recording ? Colors.white : context.ink,
          ),
        ),
      ),
    );
  }
}
