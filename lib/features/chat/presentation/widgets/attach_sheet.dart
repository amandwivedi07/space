import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

enum AttachChoice { photo, camera, video, link }

/// What to attach: photo, camera capture, a short video, or a link.
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
    return Column(
      children: [
        _AttachTile(
          icon: Icons.photo_outlined,
          title: AppStrings.sendAPhoto,
          subtitle: 'From your library',
          choice: AttachChoice.photo,
        ),
        _AttachTile(
          icon: Icons.photo_camera_outlined,
          title: 'Capture a photo',
          subtitle: 'Straight from the lens',
          choice: AttachChoice.camera,
        ),
        _AttachTile(
          icon: Icons.videocam_outlined,
          title: AppStrings.recordInstantVideo,
          subtitle: 'A clip up to thirty seconds',
          choice: AttachChoice.video,
        ),
        _AttachTile(
          icon: Icons.link_rounded,
          title: AppStrings.pasteALink,
          subtitle: 'With a comment on top',
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
      title: Text(title, style: context.text.titleSmall),
      subtitle: Text(subtitle, style: context.text.bodySmall),
      onTap: () => Navigator.of(context).pop(choice),
    );
  }
}
