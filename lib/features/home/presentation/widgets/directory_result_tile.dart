import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/directory_user.dart';

/// One person in the directory search results.
class DirectoryResultTile extends StatelessWidget {
  const DirectoryResultTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  final DirectoryUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            AppAvatar(
              name: user.name,
              palette: SpacePalette.byId(user.paletteId),
              avatarUrl: user.avatarUrl,
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(user.name,
                      style: context.text.bodyMedium,
                      overflow: TextOverflow.ellipsis),
                  // Two people can share a name; the handle is what tells
                  // them apart.
                  if (user.handle.isNotEmpty)
                    Text('@${user.handle}', style: context.text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.add_rounded, size: 20, color: context.muted),
          ],
        ),
      ),
    );
  }
}
