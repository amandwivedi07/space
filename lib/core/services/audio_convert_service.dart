import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'logger_service.dart';

/// Turns iOS WAV captures into M4A so POST /media accepts them.
class AudioConvertService {
  static const _channel = MethodChannel('space/audio_convert');

  Future<String> forUpload(String path) async {
    if (!path.toLowerCase().endsWith('.wav')) return path;
    if (kIsWeb || !Platform.isIOS) return path;

    final dir = await getTemporaryDirectory();
    final dest = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      final out = await _channel.invokeMethod<String>('wavToM4a', {
        'src': path,
        'dest': dest,
      });
      if (out != null && out.isNotEmpty) return out;
    } catch (e) {
      Log.w('wav→m4a failed: $e');
    }
    return path;
  }
}

final audioConvertProvider = Provider<AudioConvertService>(
  (ref) => AudioConvertService(),
);
