import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'logger_service.dart';

/// Real microphone capture for voice notes (m4a/AAC). Permission is requested
/// by the plugin on first use.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  Future<bool> start() async {
    try {
      if (!await _recorder.hasPermission()) {
        Log.w('microphone permission denied');
        return false;
      }
      final dir = await getTemporaryDirectory();
      _path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: _path!,
      );
      return true;
    } catch (e) {
      Log.w('recorder start failed: $e');
      return false;
    }
  }

  /// Stops and returns the recorded file path, or null if nothing usable.
  Future<String?> stop() async {
    try {
      final path = await _recorder.stop() ?? _path;
      if (path == null) return null;
      final file = File(path);
      if (!await file.exists() || await file.length() < 1024) {
        return null; // too short to be worth sending
      }
      return path;
    } catch (e) {
      Log.w('recorder stop failed: $e');
      return null;
    }
  }

  Future<void> cancel() async {
    try {
      await _recorder.cancel();
    } catch (_) {}
  }

  void dispose() => _recorder.dispose();
}

final audioRecorderProvider = Provider<AudioRecorderService>((ref) {
  final service = AudioRecorderService();
  ref.onDispose(service.dispose);
  return service;
});
