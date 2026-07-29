import 'dart:io';

import 'package:flutter/material.dart';

import '../constants/palettes.dart';
import '../extensions/string_x.dart';
import '../theme/app_typography.dart';

/// Gradient avatar with initial, ring and size presets. A picture wins when
/// there is one: [photoPath] for a locally chosen file, [avatarUrl] for the
/// Google photo the identity provider gave us. Apple hands over no picture, so
/// the initial is the normal case there rather than a failure.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.palette = SpacePalette.ember,
    this.size = 48,
    this.photoPath,
    this.avatarUrl,
    this.ringColor,
  });

  final String name;
  final SpacePalette palette;
  final double size;
  final String? photoPath;
  final String? avatarUrl;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? photo = switch ((photoPath, avatarUrl)) {
      (final p?, _) when p.isNotEmpty => FileImage(File(p)),
      (_, final u?) when u.isNotEmpty => NetworkImage(u),
      _ => null,
    };
    final hasPhoto = photo != null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto ? null : palette.gradient,
        image: hasPhoto
            // A photo that fails to load falls back to the gradient beneath it.
            ? DecorationImage(image: photo, fit: BoxFit.cover)
            : null,
        border: ringColor == null
            ? Border.all(color: Colors.black.withValues(alpha: 0.06))
            : Border.all(color: ringColor!, width: 2),
        boxShadow: [
          BoxShadow(
            color: palette.to.withValues(alpha: 0.28),
            blurRadius: size / 5,
            offset: Offset(0, size / 14),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              name.initial,
              style: AppTypography.display(Colors.white, size * 0.42)
                  .copyWith(fontStyle: FontStyle.normal),
            ),
    );
  }
}

/// Overlapping avatar stack for circles.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.names,
    required this.palettes,
    this.size = 34,
    this.maxVisible = 3,
  });

  final List<String> names;
  final List<SpacePalette> palettes;
  final double size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = names.take(maxVisible).toList();
    return SizedBox(
      width: size + (visible.length - 1) * size * 0.62,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * size * 0.62,
              child: AppAvatar(
                name: visible[i],
                palette: palettes[i % palettes.length],
                size: size,
                ringColor: Theme.of(context).colorScheme.surface,
              ),
            ),
        ],
      ),
    );
  }
}
