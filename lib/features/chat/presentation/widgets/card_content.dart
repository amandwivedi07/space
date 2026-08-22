import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/helpers/date_formatter.dart';
import '../../../../core/services/share_launcher_service.dart';
import '../../../../core/services/voice_player_service.dart';
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

class _VoiceContent extends ConsumerStatefulWidget {
  const _VoiceContent({required this.card});

  final SpaceCard card;

  @override
  ConsumerState<_VoiceContent> createState() => _VoiceContentState();
}

class _VoiceContentState extends ConsumerState<_VoiceContent> {
  // Captured up front, because `ref` cannot be touched in dispose() — Riverpod
  // has already torn it down by then and throws. Holding the notifier and a
  // plain bool keeps the teardown free of any ref access.
  VoicePlayerNotifier? _player;
  bool _wasLoaded = false;

  @override
  void initState() {
    super.initState();
    _player = ref.read(voicePlayerProvider.notifier);
  }

  // A voice note must not outlive the card it belongs to. Cards fade, get
  // deleted, and scroll out of the room — and the player is a single shared
  // instance, so without this it would carry on talking after the thing that
  // held it had gone. Disposal is the one signal covering all of those routes.
  @override
  void dispose() {
    if (_wasLoaded) _player?.stop();
    super.dispose();
  }

  /// Long transcripts stepped down harder than before: a thirty-second note is
  /// a paragraph, and at 24pt it filled the screen.
  double _fontSize(String text) {
    final len = text.trim().length;
    if (len <= 12) return 38;
    if (len <= 28) return 30;
    if (len <= 60) return 24;
    if (len <= 140) return 19;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final ink = context.ink;
    final transcript = card.body.trim();
    final source = card.mediaPath ?? '';
    final playback = ref.watch(voicePlayerProvider);
    final isThis = playback.isLoaded(card.id);
    final playing = playback.isPlaying(card.id);
    _wasLoaded = isThis;
    // Only this card's own progress lights the waveform; another card playing
    // must not animate this one.
    final progress = isThis ? playback.progress : 0.0;

    // Deterministic waveform from the card id.
    final barCount = 32;
    final heights = List.generate(
      barCount,
      (i) => 8.0 +
          ((card.id.codeUnitAt(i % card.id.length) * (i + 3)) % 28).toDouble(),
    );

    final duration = DateFormatter.clock(Duration(seconds: card.durationSec));

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Waveform + pause icon, top (matches the Lovable voice card feel).
          Row(
            children: [
              GestureDetector(
                onTap: source.isEmpty
                    ? null
                    : () => ref
                        .read(voicePlayerProvider.notifier)
                        .toggle(card.id, source),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: context.ink.withValues(alpha: playing ? 0.18 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 26,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              // Expanded, not a fixed 260: the button and gap already take 78,
              // so on a narrower phone the row demanded 338 inside a card that
              // could not give it and overflowed by 88 pixels.
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final (i, h) in heights.indexed)
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: h,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1.1),
                              decoration: BoxDecoration(
                                // Bars already played are solid, the rest
                                // stay faint — the waveform doubles as the
                                // progress bar, so nothing else has to.
                                color: ink.withValues(
                                  alpha: (i + 1) / heights.length <= progress
                                      ? 0.95
                                      : 0.3,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Grows as words arrive and collapses to nothing before playback, so
          // an unplayed note is a compact pill rather than a tall empty card.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: transcript.isEmpty
                ? const SizedBox(width: double.infinity)
                : _RevealingTranscript(
                    transcript: transcript,
                    // Before the note has been played there is nothing to
                    // reveal, so the card stays a voice note rather than a
                    // transcript with a play button attached.
                    elapsed: playback.completed && isThis
                        ? const Duration(days: 1)
                        : (isThis ? playback.position : Duration.zero),
                    total: isThis && playback.duration > Duration.zero
                        ? playback.duration
                        : Duration(seconds: card.durationSec),
                    style: AppTypography.display(ink, _fontSize(transcript)),
                    mutedColor: context.muted,
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            // Counts up while playing, so the label is the clock rather than
            // a static length you have to hold in your head.
            isThis && playback.duration > Duration.zero
                ? 'VOICE · ${DateFormatter.clock(playback.position)}'
                    ' / ${DateFormatter.clock(playback.duration)}'
                : 'VOICE · $duration',
            style: AppTypography.mono(context.muted, 10),
          ),
        ],
      ),
    );
  }
}

/// The transcript, arriving as the note plays rather than sitting there before
/// a word has been heard.
///
/// There are no per-word timings to work from — a card stores the transcript
/// as plain text — so the pace has to be estimated. Spreading the words evenly
/// across the recording was the obvious guess and a bad one: people carry on
/// recording after they stop talking, so real notes came in at 0.25–1.6 words
/// per second against natural speech of about 2.6. The text fell behind the
/// voice, and the opening words were audible before they were readable.
///
/// So words are paced at natural speaking rate instead, and only sped up if
/// the note is denser than that. Running slightly ahead of the voice is how
/// subtitles behave and reads fine; running behind does not.
class _RevealingTranscript extends StatelessWidget {
  const _RevealingTranscript({
    required this.transcript,
    required this.elapsed,
    required this.total,
    required this.style,
    required this.mutedColor,
  });

  /// Words per second of unhurried speech — the floor for the reveal.
  static const _naturalWordsPerSecond = 2.6;

  /// The recogniser needs a moment to start, so the first word tends to land
  /// slightly late. A small head start puts it back under the voice.
  static const _lead = Duration(milliseconds: 250);

  final String transcript;

  /// How far into the note playback is. Zero means nothing has been heard.
  final Duration elapsed;

  /// The note's full length, used only to spot a note denser than natural
  /// speech, where the even spread is the faster of the two.
  final Duration total;

  final TextStyle style;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final words = transcript.split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return const SizedBox.shrink();

    // At rest the lead must not apply, or a note nobody has played would sit
    // there showing its first word.
    if (elapsed <= Duration.zero) return const SizedBox.shrink();
    final seconds = (elapsed + _lead).inMilliseconds / 1000;

    final totalSeconds = total.inMilliseconds / 1000;
    final evenRate = totalSeconds > 0 ? words.length / totalSeconds : 0.0;
    final rate = evenRate > _naturalWordsPerSecond
        ? evenRate
        : _naturalWordsPerSecond;

    final spoken = (seconds * rate).ceil().clamp(0, words.length);
    if (spoken == 0) return const SizedBox.shrink();

    // Only the words heard so far are built. An earlier version laid out the
    // whole transcript invisibly to stop lines reflowing as words appeared —
    // but invisible text still takes up space, so a thirty-second note
    // reserved a tall empty block and overflowed the card by 20 pixels. A
    // little reflow is the cheaper price.
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 2,
        children: [
          for (final (i, word) in words.take(spoken).indexed)
            _Word(
              key: ValueKey(i),
              word: word,
              style: style,
              // The word currently being said is dimmed, the ones behind it
              // are solid — the same grammar as the live transcript while
              // recording, so the two states read as one idea.
              spoken: i < spoken - 1,
              mutedColor: mutedColor,
            ),
        ],
      ),
    );
  }
}

/// One word, fading and rising into place as it is heard.
class _Word extends StatefulWidget {
  const _Word({
    super.key,
    required this.word,
    required this.style,
    required this.spoken,
    required this.mutedColor,
  });

  final String word;
  final TextStyle style;
  final bool spoken;
  final Color mutedColor;

  @override
  State<_Word> createState() => _WordState();
}

class _WordState extends State<_Word>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  // Built once, not per frame. These used to be constructed inside build(),
  // which runs on every position tick — each rebuild attached another listener
  // to the controller and never removed it, so a long transcript leaked
  // hundreds of animations while it played.
  late final CurvedAnimation _curved =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(_curved);

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Driven by the word's own controller, which runs once when it is first
    // built. Tying it to a rebuild-time flag instead would replay the entrance
    // on every position tick.
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: _slide,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: widget.spoken
              ? widget.style
              : widget.style.copyWith(color: widget.mutedColor),
          child: Text(widget.word),
        ),
      ),
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
