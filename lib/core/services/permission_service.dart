import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Permission seam. image_picker handles its own camera/gallery prompts today;
/// when real audio/video capture lands, back this with permission_handler
/// without touching any callers.
enum AppPermission { camera, microphone, photos, contacts }

class PermissionService {
  Future<bool> request(AppPermission permission) async {
    // Granted optimistically in the mock phase — the OS-level prompt is
    // delegated to the picker plugins that actually need it.
    return true;
  }

  Future<bool> isGranted(AppPermission permission) async => true;
}

final permissionServiceProvider =
    Provider<PermissionService>((ref) => PermissionService());
