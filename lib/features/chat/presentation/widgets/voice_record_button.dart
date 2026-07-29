import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/helpers/date_formatter.dart';
import '../../../../core/services/audio_recorder_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Hold-to-speak mic — records real audio and hands back (filePath, seconds).
class VoiceRecordButton extends ConsumerStatefulWidget {
  const VoiceRecordButton({super.key, required this.onRecorded});

  /// (path to the recorded file, duration in seconds)
  final void Function(String path, int seconds) onRecorded;

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton> {
  Timer? _ticker;
  int _elapsed = 0;
  bool _recording = false;

  Future<void> _start() async {
    final started = await ref.read(audioRecorderProvider).start();
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Microphone unavailable')));
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _recording = true;
      _elapsed = 0;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    final seconds = _elapsed.clamp(1, 120);
    if (mounted) setState(() => _recording = false);
    final path = await ref.read(audioRecorderProvider).stop();
    if (path != null) widget.onRecorded(path, seconds);
  }

  void _cancelSilently() {
    _ticker?.cancel();
    ref.read(audioRecorderProvider).cancel();
    if (mounted) setState(() => _recording = false);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.holdToSpeak,
      child: GestureDetector(
        onLongPressStart: (_) => _start(),
        onLongPressEnd: (_) => _stop(),
        onLongPressCancel: _cancelSilently,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _recording
                ? AppColors.danger
                : context.ink.withValues(alpha: 0.06),
          ),
          child: _recording
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.graphic_eq_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.clock(Duration(seconds: _elapsed)),
                      style: context.text.bodySmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                )
              : Icon(Icons.mic_none_rounded, size: 20, color: context.ink),
        ),
      ),
    );
  }
}
