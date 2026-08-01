import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/helpers/date_formatter.dart';
import '../../../../core/services/share_launcher_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../data/models/space_card.dart';
import '../../data/repositories/link_preview_repository.dart';
import 'media_card_content.dart';

/// Renders the body of a card by type. View-once covering is handled
/// by the parent bubble.
class CardContent extends ConsumerWidget {
  const CardContent({super.key, required this.card});

  final SpaceCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (card.type) {
      CardType.text => Text(card.body, style: context.text.bodyLarge),
      CardType.photo ||
      CardType.video ||
      CardType.aiImage ||
      CardType.aiVideo =>
        MediaCardContent(card: card),
      CardType.voice => _VoiceContent(card: card),
      CardType.link => _LinkContent(card: card),
      CardType.file => _FileContent(card: card),
    };
  }
}

class _VoiceContent extends StatelessWidget {
  const _VoiceContent({required this.card});

  final SpaceCard card;

  @override
  Widget build(BuildContext context) {
    final ink = context.ink;
    // Deterministic little waveform from the card id.
    final heights = List.generate(
        18, (i) => 6.0 + ((card.id.codeUnitAt(i % card.id.length) * (i + 3)) % 16));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_circle_fill_rounded, size: 30, color: ink),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final h in heights)
              Container(
                width: 2.4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1.1),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Text(DateFormatter.clock(Duration(seconds: card.durationSec)),
            style: context.text.bodySmall),
      ],
    );
  }
}

class _LinkContent extends ConsumerWidget {
  const _LinkContent({required this.card});

  final SpaceCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = card.linkUrl ?? '';
    final host = Uri.tryParse(url.startsWith('http') ? url : 'https://$url')
            ?.host ??
        url;
    // The preview is decoration, never a gate: whatever the server comes back
    // with (including nothing), the domain and the tap target are already
    // there, so the card is useful the moment it renders.
    final preview = ref.watch(linkPreviewProvider(url)).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (card.body.isNotEmpty) ...[
          Text(card.body, style: context.text.bodyLarge),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: () => ref.read(shareLauncherProvider).openLink(url),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.ink.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: preview != null && preview.isRich
                ? _RichPreview(preview: preview, host: host)
                : _PlainChip(host: host),
          ),
        ),
      ],
    );
  }
}

/// What a link looked like before previews, and still does when a page has no
/// metadata to read.
class _PlainChip extends StatelessWidget {
  const _PlainChip({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 16, color: context.muted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(host,
                style: context.text.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text('Open link →', style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _RichPreview extends StatelessWidget {
  const _RichPreview({required this.preview, required this.host});

  final LinkPreview preview;
  final String host;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (preview.imageUrl.isNotEmpty)
          AspectRatio(
            aspectRatio: 1.91, // what og:image is authored against
            child: AppNetworkImage(source: preview.imageUrl, radius: 0),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (preview.siteName.isNotEmpty ? preview.siteName : host)
                    .toUpperCase(),
                style: AppTypography.mono(context.muted, 8),
              ),
              if (preview.title.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(preview.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
              if (preview.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(preview.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FileContent extends StatelessWidget {
  const _FileContent({required this.card});

  final SpaceCard card;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.description_outlined, size: 22, color: context.muted),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.body.isEmpty ? 'A file' : card.body,
                style: context.text.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
            Text(AppStrings.savedLocally, style: context.text.bodySmall),
          ],
        ),
      ],
    );
  }
}
