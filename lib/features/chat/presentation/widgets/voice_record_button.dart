import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/helpers/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';

/// Hold-to-speak mic. Recording is simulated (duration only) — swap the
/// timer for a real recorder plugin without changing the API.
class VoiceRecordButton extends StatefulWidget {
  const VoiceRecordButton({super.key, required this.onRecorded});

  final ValueChanged<int> onRecorded; // seconds

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  Timer? _ticker;
  int _elapsed = 0;
  bool _recording = false;

  void _start() {
    setState(() {
      _recording = true;
      _elapsed = 0;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
  }

  void _stop() {
    _ticker?.cancel();
    final seconds = _elapsed.clamp(1, 120);
    setState(() => _recording = false);
    widget.onRecorded(seconds);
  }

  void _cancelSilently() {
    _ticker?.cancel();
    setState(() => _recording = false);
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
