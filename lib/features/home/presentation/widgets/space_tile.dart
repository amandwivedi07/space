import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/constants/presence.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/extensions/datetime_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/avatar_url.dart';

/// The picture behind a tile: their photo when there is one, otherwise the
/// palette gradient with their initial. A tile is mostly photograph, so the
/// fallback has to carry the whole surface rather than sit in a corner.
class TileBackdrop extends StatelessWidget {
  const TileBackdrop({
    super.key,
    required this.name,
    required this.paletteId,
    this.avatarUrl,
    this.photoPath,
  });

  final String name;
  final String paletteId;
  final String? avatarUrl;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final palette = SpacePalette.byId(paletteId);

    // LayoutBuilder, because the right image size is the one this tile is
    // about to be drawn at: the featured slot is nearly twice the width of a
    // grid tile, and asking for one size for both wastes bytes on the small
    // one or blurs the large one.
    return LayoutBuilder(
      builder: (context, constraints) {
        final ImageProvider? photo = switch ((photoPath, avatarUrl)) {
          (final p?, _) when p.isNotEmpty => FileImage(File(p)),
          (_, final u?) when u.isNotEmpty => NetworkImage(
              sizedAvatarUrl(
                u,
                logicalSize: longestEdge(
                    constraints.maxWidth, constraints.maxHeight),
                devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
              ),
            ),
          _ => null,
        };

        if (photo != null) {
          return Image(image: photo, fit: BoxFit.cover, errorBuilder:
              (context, _, _) => _Initial(name: name, palette: palette));
        }
        return _Initial(name: name, palette: palette);
      },
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.name, required this.palette});

  final String name;
  final SpacePalette palette;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.from, palette.to],
        ),
      ),
      child: Center(
        child: Text(letter,
            style: AppTypography.display(
                Colors.white.withValues(alpha: 0.9), 56)),
      ),
    );
  }
}

/// The scrim that keeps a name legible over an unknown photograph. Without it
/// a light picture swallows white text entirely.
class TileScrim extends StatelessWidget {
  const TileScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.28),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
    );
  }
}

/// "● HERE NOW" — shown only when they actually are. A badge that is always
/// present says nothing.
class HereNowBadge extends StatelessWidget {
  const HereNowBadge({super.key, required this.presence});

  final Presence presence;

  @override
  Widget build(BuildContext context) {
    if (!AppConstants.showPresence) return const SizedBox.shrink();
    if (presence != Presence.here) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Dot(),
          const SizedBox(width: 7),
          Text('HERE NOW', style: AppTypography.mono(Colors.white, 8.5)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF5FD08A),
          shape: BoxShape.circle,
        ),
      );
}

/// The unread count, in the accent so it reads as "something is waiting".
class UnreadPip extends StatelessWidget {
  const UnreadPip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.primary,
        shape: BoxShape.circle,
      ),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// One person, as a tile: their face fills it, their name sits on the glass.
class PersonTile extends StatelessWidget {
  const PersonTile({
    super.key,
    required this.name,
    required this.paletteId,
    required this.presence,
    required this.unread,
    required this.lastActivity,
    required this.onTap,
    this.avatarUrl,
    this.photoPath,
    this.height = 200,
  });

  final String name;
  final String paletteId;
  final Presence presence;
  final int unread;
  final DateTime lastActivity;
  final VoidCallback onTap;
  final String? avatarUrl;
  final String? photoPath;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TileBackdrop(
                name: name,
                paletteId: paletteId,
                avatarUrl: avatarUrl,
                photoPath: photoPath,
              ),
              const TileScrim(),
              Positioned(
                left: 12,
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    Flexible(child: HereNowBadge(presence: presence)),
                    const Spacer(),
                    Text(lastActivity.compactAgo,
                        style: AppTypography.mono(
                            Colors.white.withValues(alpha: 0.75), 8.5)),
                  ],
                ),
              ),
              if (unread > 0)
                Positioned(right: 12, top: 46, child: UnreadPip(count: unread)),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                // Two lines: the reference only ever showed short first
                // names, but real accounts carry full legal ones and
                // "Aprameya Rad…" is not a label anyone wants on their face.
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(Colors.white, 19),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circle, given the full width: the members' faces side by side, so the
/// tile shows who is in it before you read the name.
class CircleTile extends StatelessWidget {
  const CircleTile({
    super.key,
    required this.name,
    required this.faces,
    required this.presence,
    required this.unread,
    required this.lastActivity,
    required this.onTap,
    this.featured = true,
  });

  /// (name, paletteId, avatarUrl) per member, in join order.
  final List<(String, String, String)> faces;
  final String name;
  final Presence presence;
  final int unread;
  final DateTime lastActivity;
  final VoidCallback onTap;

  /// Wide in the featured slot, portrait in the grid. In the grid there is
  /// only room for two faces before they become slivers.
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final shown = faces.take(featured ? 3 : 2).toList();
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: featured ? 240 : 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (shown.isEmpty)
                TileBackdrop(name: name, paletteId: 'iris')
              else
                Row(
                  // stretch, not the default centre: a Row hands its children
                  // their intrinsic height, which left the faces floating in a
                  // band with dark gaps above and below them.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (who, palette, url) in shown)
                      Expanded(
                        child: TileBackdrop(
                            name: who, paletteId: palette, avatarUrl: url),
                      ),
                  ],
                ),
              const TileScrim(),
              Positioned(
                left: 14,
                top: 14,
                right: 14,
                child: Row(
                  children: [
                    Flexible(child: HereNowBadge(presence: presence)),
                    const Spacer(),
                    Text(lastActivity.compactAgo,
                        style: AppTypography.mono(
                            Colors.white.withValues(alpha: 0.75), 8.5)),
                  ],
                ),
              ),
              if (unread > 0)
                Positioned(right: 14, top: 48, child: UnreadPip(count: unread)),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        maxLines: featured ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(
                            Colors.white, featured ? 27 : 19)),
                    const SizedBox(height: 6),
                    Text('${faces.length} PEOPLE',
                        style: AppTypography.mono(
                            Colors.white.withValues(alpha: 0.75), 8.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A broadcast tile — the wide shape a circle uses, because a broadcast is
/// also "one message, several people". Two forms:
///   • yours: the way into the everyone room
///   • theirs: someone told a group of people something, and you are in it
class BroadcastTile extends StatelessWidget {
  const BroadcastTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.name,
    this.avatarUrl,
    this.unread = false,
    this.mine = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? name;
  final String? avatarUrl;
  final bool unread;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 132,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!mine && (avatarUrl?.isNotEmpty ?? false))
                TileBackdrop(
                    name: name ?? title,
                    paletteId: 'iris',
                    avatarUrl: avatarUrl)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [accent, accent.withValues(alpha: 0.65)],
                    ),
                  ),
                ),
              if (!mine) const TileScrim(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppTypography.display(Colors.white, 23)),
                          const SizedBox(height: 5),
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.mono(
                                  Colors.white.withValues(alpha: 0.8), 8.5)),
                        ],
                      ),
                    ),
                    if (unread) const UnreadPip(count: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
