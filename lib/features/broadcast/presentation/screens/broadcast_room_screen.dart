import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/fade_options.dart';
import '../../../../core/constants/palettes.dart';
import '../../../../core/constants/presence.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../chat/data/models/space_card.dart';
import '../../../chat/presentation/widgets/empty_room_view.dart';
import '../../../chat/presentation/widgets/fade_timer_sheet.dart';
import '../../../chat/presentation/widgets/story_card_view.dart';
import '../../../chat/presentation/widgets/story_progress_bar.dart';
import '../../../space_ai/data/repositories/space_ai_repository.dart';
import '../../../space_ai/presentation/screens/space_ai_screen.dart';
import '../../data/repositories/broadcast_repository.dart';

/// "everyone" — a room whose other side is every space you have.
///
/// It deliberately looks and behaves like an ordinary room, because that is
/// what it is from the writer's side: you say one thing, and each person
/// receives it as a message meant for them. The only place the truth surfaces
/// is the audience line and the confirmation before sending.
class BroadcastRoomScreen extends ConsumerStatefulWidget {
  const BroadcastRoomScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const BroadcastRoomScreen(),
      ));

  @override
  ConsumerState<BroadcastRoomScreen> createState() =>
      _BroadcastRoomScreenState();
}

class _BroadcastRoomScreenState extends ConsumerState<BroadcastRoomScreen> {
  final _controller = TextEditingController();
  List<SpaceCard> _cards = const [];
  int _index = 0;
  FadeOption _fade = FadeOption.m60;
  bool _sending = false;
  bool _fromAi = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // Same one-second clock the room uses, so a broadcast counts down and
    // disappears here exactly as it does for the people who received it.
    _ticker = Timer.periodic(AppConstants.fadeTick, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await ref.read(broadcastRepositoryProvider).cards();
    if (!mounted) return;
    result.when(
      success: (cards) => setState(() {
        _cards = cards..sort((a, b) => a.sentAt.compareTo(b.sentAt));
        _index = _cards.isEmpty ? 0 : _cards.length - 1;
      }),
      failure: (_) {},
    );
  }

  Future<void> _pickFade() async {
    final chosen = await FadeTimerSheet.show(context, _fade);
    if (chosen != null) setState(() => _fade = chosen);
  }

  Future<void> _draftWithAi() async {
    final outcome = await SpaceAiScreen.open(context);
    if (outcome is AiDraftChosen && mounted) {
      _controller.text = outcome.text;
      setState(() => _fromAi = true);
    }
  }

  Future<void> _send(int audience) async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;

    // One deliberate pause before reaching everyone at once. The count is in
    // the question because "everyone" is not a number anyone pictures.
    final sure = await AppDialog.confirm(
      context,
      title: 'Send to $audience ${audience == 1 ? "person" : "people"}?',
      body: 'Each of them sees it as an ordinary message from you. '
          'Nobody is told it went to anyone else.',
      confirmLabel: 'Send',
    );
    if (!sure || !mounted) return;

    setState(() => _sending = true);
    final result = await ref
        .read(broadcastRepositoryProvider)
        .send(body: body, fade: _fade, aiGenerated: _fromAi);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _fromAi = false;
    });

    result.when(
      success: (sent) {
        _controller.clear();
        FocusScope.of(context).unfocus();
        AppToast.show(
          context,
          'Sent to ${sent.recipientCount} '
          '${sent.recipientCount == 1 ? "person" : "people"}',
          icon: Icons.campaign_rounded,
        );
        _load();
      },
      failure: (message) => AppDialog.alert(context,
          title: "Couldn't send", body: message),
    );
  }

  void _tap(TapUpDetails details) {
    if (_cards.isEmpty) return;
    final width = MediaQuery.sizeOf(context).width;
    setState(() {
      if (details.globalPosition.dx < width / 3) {
        if (_index > 0) _index--;
      } else if (_index < _cards.length - 1) {
        _index++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final audience = ref.watch(broadcastAudienceProvider).valueOrNull;
    final live = _cards.where((c) => !c.expired).toList();
    if (_index > live.length - 1) _index = (live.length - 1).clamp(0, 999);
    final current = live.isEmpty ? null : live[_index];

    final background = context.theme.scaffoldBackgroundColor;
    final palette = SpacePalette.byId('iris');
    final tint = context.isDark
        ? Color.lerp(background, palette.to, 0.22)!
        : Color.lerp(background, palette.from, 0.30)!;

    return Scaffold(
      backgroundColor: background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tint, background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              StoryProgressBar(cards: live, index: _index),
              _Header(audience: audience, onClose: () => Navigator.pop(context)),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _tap,
                  child: current == null
                      ? EmptyRoomView(
                          name: 'everyone',
                          paletteId: 'iris',
                          presence: Presence.away,
                          fade: _fade,
                          onOpenAi:
                              (ref.watch(spaceAiAvailableProvider).valueOrNull ??
                                      false)
                                  ? _draftWithAi
                                  : null,
                        )
                      : StoryCardView(card: current),
                ),
              ),
              _Composer(
                controller: _controller,
                fade: _fade,
                sending: _sending,
                canSend: (audience ?? 0) > 0,
                onFade: _pickFade,
                onAi: _draftWithAi,
                onSend: () => _send(audience ?? 0),
                onChanged: () => setState(() => _fromAi = false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.audience, required this.onClose});

  /// Null while the count is still in flight. Kept nullable on purpose:
  /// collapsing it to 0 told the reader they had nobody at the exact moment
  /// the screen opened, which is the one moment they cannot check.
  final int? audience;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('everyone',
                    style: AppTypography.display(context.ink, 20),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                // The one place the truth is stated outright: this room has
                // a size, and you should know it before you speak.
                Text(
                  switch (audience) {
                    null => 'COUNTING…',
                    0 => 'NOBODY YET — OPEN A SPACE FIRST',
                    1 => 'GOES TO 1 PERSON',
                    final n => 'GOES TO $n PEOPLE',
                  },
                  style: AppTypography.mono(context.muted, 9),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 21, color: context.ink),
          ),
        ],
      ),
    );
  }
}

/// The room composer's shape, with the two controls a broadcast actually has.
/// Attachments and voice are deliberately absent rather than present and
/// dead — this first version sends words.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.fade,
    required this.sending,
    required this.canSend,
    required this.onFade,
    required this.onAi,
    required this.onSend,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FadeOption fade;
  final bool sending;
  final bool canSend;
  final VoidCallback onFade;
  final VoidCallback onAi;
  final VoidCallback onSend;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
              top: BorderSide(color: context.ink.withValues(alpha: 0.06))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: onAi,
              tooltip: 'Draft with SpaceAI',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(Icons.auto_awesome_outlined, color: context.ink),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.ink.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(32),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => onChanged(),
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Type to everyone…',
                          hintMaxLines: 1,
                          isDense: true,
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onFade,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.ink.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 12, color: context.muted),
                            const SizedBox(width: 5),
                            Text(fade.chipLabel,
                                style: AppTypography.mono(context.muted, 8.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: hasText && canSend && !sending ? onSend : null,
              style: IconButton.styleFrom(
                backgroundColor: hasText && canSend && !sending
                    ? context.colors.primary
                    : context.ink.withValues(alpha: 0.15),
                minimumSize: const Size(46, 46),
              ),
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_upward_rounded,
                      size: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
