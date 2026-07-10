import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'logger_service.dart';

/// Wraps image_picker so features never touch the plugin directly.
class MediaPickerService {
  MediaPickerService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickImage({bool fromCamera = false}) async {
    try {
      final file = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      return file?.path;
    } catch (e, s) {
      Log.e('Image pick failed', error: e, stack: s);
      return null;
    }
  }

  Future<String?> pickVideo({bool fromCamera = false}) async {
    try {
      final file = await _picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      return file?.path;
    } catch (e, s) {
      Log.e('Video pick failed', error: e, stack: s);
      return null;
    }
  }
}

final mediaPickerProvider =
    Provider<MediaPickerService>((ref) => MediaPickerService());
