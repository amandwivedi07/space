import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

enum AttachChoice { camera, recordVideo, photo, video, link }

/// The attach menu: Camera · Record video · Photo · Video · Link.
/// (Documents are omitted until a real file picker + upload is wired.)
class AttachSheet extends StatelessWidget {
  const AttachSheet({super.key});

  static Future<AttachChoice?> show(BuildContext context) =>
      AppBottomSheet.show<AttachChoice>(
        context,
        eyebrow: 'Attach',
        title: 'Add something to the moment',
        child: const AttachSheet(),
      );

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _AttachTile(
          icon: Icons.photo_camera_outlined,
          title: 'Camera',
          subtitle: 'TAKE A PHOTO NOW',
          choice: AttachChoice.camera,
        ),
        _AttachTile(
          icon: Icons.videocam_outlined,
          title: 'Record video',
          subtitle: 'CAPTURE LIVE',
          choice: AttachChoice.recordVideo,
        ),
        _AttachTile(
          icon: Icons.photo_outlined,
          title: 'Photo',
          subtitle: 'FROM GALLERY',
          choice: AttachChoice.photo,
        ),
        _AttachTile(
          icon: Icons.video_library_outlined,
          title: 'Video',
          subtitle: 'FROM GALLERY',
          choice: AttachChoice.video,
        ),
        _AttachTile(
          icon: Icons.link_rounded,
          title: 'Link',
          subtitle: 'PASTE A URL',
          choice: AttachChoice.link,
        ),
      ],
    );
  }
}

class _AttachTile extends StatelessWidget {
  const _AttachTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.choice,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AttachChoice choice;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.ink.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: context.ink),
      ),
      title:
          Text(title, style: AppTypography.display(context.ink, 17)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: AppTypography.mono(context.muted, 8)),
      ),
      onTap: () => Navigator.of(context).pop(choice),
    );
  }
}
