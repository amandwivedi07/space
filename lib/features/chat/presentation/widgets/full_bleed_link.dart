import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/share_launcher_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../data/models/space_card.dart';
import '../../data/repositories/link_preview_repository.dart';

/// A shared link, given the whole stage: the page's own picture edge to edge,
/// its title over a scrim. Only the text block opens the link — tapping the
/// picture still moves the story on, the way a story is meant to behave.
class FullBleedLink extends ConsumerWidget {
  const FullBleedLink({super.key, required this.card, required this.preview});

  final SpaceCard card;
  final LinkPreview preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = card.linkUrl ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkImage(source: preview.imageUrl, radius: 0),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 340,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.78),
                  Colors.black.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: GestureDetector(
            onTap: () => ref.read(shareLauncherProvider).openLink(url),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (card.body.isNotEmpty) ...[
                  Text(card.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(Colors.white, 19)),
                  const SizedBox(height: 12),
                ],
                Text(
                  (preview.siteName.isNotEmpty ? preview.siteName : preview.host)
                      .toUpperCase(),
                  style: AppTypography.mono(
                      Colors.white.withValues(alpha: 0.7), 9),
                ),
                const SizedBox(height: 7),
                if (preview.title.isNotEmpty)
                  Text(preview.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(Colors.white, 25)),
                if (preview.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(preview.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.8))),
                ],
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 7),
                      Text('Open link  →',
                          style: AppTypography.mono(Colors.white, 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// True when this card can fill the stage — a link only earns the full screen
/// once its picture is in hand. Without one there is nothing to fill it with,
/// so it stays a card.
LinkPreview? fullBleedLinkPreview(WidgetRef ref, SpaceCard card) {
  if (card.type != CardType.link) return null;
  final url = card.linkUrl ?? '';
  if (url.isEmpty) return null;
  final preview = ref.watch(linkPreviewProvider(url)).valueOrNull;
  if (preview == null || preview.imageUrl.isEmpty) return null;
  return preview;
}
