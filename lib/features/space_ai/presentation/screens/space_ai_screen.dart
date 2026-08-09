import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../data/models/ai_result.dart';
import '../../data/models/ai_turn.dart';
import '../viewmodels/space_ai_viewmodel.dart';

/// What the screen hands back to the composer.
sealed class AiOutcome {
  const AiOutcome();
}

class AiDraftChosen extends AiOutcome {
  const AiDraftChosen(this.text);
  final String text;
}

/// A generated picture, already stored server-side. [url] is a media URL the
/// card endpoint accepts directly — no second upload.
class AiMediaReady extends AiOutcome {
  const AiMediaReady(this.url);
  final String url;
}

/// SpaceAI, full screen and conversational. Opened from a card it arrives
/// already answering; opened from the composer it waits for a first line.
class SpaceAiScreen extends ConsumerStatefulWidget {
  const SpaceAiScreen({
    super.key,
    this.replyTo,
    this.replyToName,
    this.forBroadcast = false,
  });

  /// The message on screen when SpaceAI was opened, and who said it.
  final String? replyTo;
  final String? replyToName;

  /// Composing for everyone rather than one person: only the wording of the
  /// promise changes, because the drafting is the same act either way.
  final bool forBroadcast;

  static Future<AiOutcome?> open(
    BuildContext context, {
    String? replyTo,
    String? replyToName,
    bool forBroadcast = false,
  }) =>
      Navigator.of(context).push<AiOutcome>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SpaceAiScreen(
          replyTo: replyTo,
          replyToName: replyToName,
          forBroadcast: forBroadcast,
        ),
      ));

  @override
  ConsumerState<SpaceAiScreen> createState() => _SpaceAiScreenState();
}

class _SpaceAiScreenState extends ConsumerState<SpaceAiScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final message = widget.replyTo?.trim();
    if (message != null && message.isNotEmpty) {
      // After the first frame: the autoDispose provider must be alive (held by
      // this widget's watch) before we ask it to work.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(spaceAiViewModelProvider.notifier)
              .beginReply(widget.replyToName ?? 'them', message);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() {});
    ref.read(spaceAiViewModelProvider.notifier).ask(text);
  }

  /// Keeps the newest turn in view as the thread grows.
  void _stickToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spaceAiViewModelProvider);
    ref.listen(spaceAiViewModelProvider, (_, _) => _stickToBottom());

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              mode: state.mode,
              onMode: ref.read(spaceAiViewModelProvider.notifier).setMode,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: state.isEmpty
                  ? _Blank(
                      mode: state.mode,
                      forBroadcast: widget.forBroadcast,
                      onPrompt: (text) =>
                          ref.read(spaceAiViewModelProvider.notifier).ask(text),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: state.turns.length,
                      itemBuilder: (context, i) => _TurnView(
                        turn: state.turns[i],
                        onChoose: (text) =>
                            Navigator.of(context).pop(AiDraftChosen(text)),
                        onSendPicture: (url) =>
                            Navigator.of(context).pop(AiMediaReady(url)),
                      ),
                    ),
            ),
            _Input(
              controller: _controller,
              hint: switch (state.mode) {
                AiKind.draft => AppStrings.whatToSay,
                AiKind.image => AppStrings.describeImage,
              },
              busy: state.busy,
              onSend: _send,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.mode, required this.onMode, required this.onClose});

  final AiKind mode;
  final ValueChanged<AiKind> onMode;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: Text('←  CLOSE',
                style: AppTypography.mono(context.muted, 10)),
          ),
          const Spacer(),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: context.colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('SpaceAI', style: AppTypography.display(context.ink, 19)),
          const Spacer(),
          _Modes(mode: mode, onMode: onMode),
        ],
      ),
    );
  }
}

/// WRITE / IMAGE. Video needs a model deployment the backend does not have, so
/// it is absent rather than present and dead.
class _Modes extends StatelessWidget {
  const _Modes({required this.mode, required this.onMode});

  final AiKind mode;
  final ValueChanged<AiKind> onMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.ink.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (kind, label) in const [
            (AiKind.draft, 'WRITE'),
            (AiKind.image, 'IMAGE'),
          ])
            GestureDetector(
              onTap: () => onMode(kind),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: mode == kind
                      ? context.colors.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: AppTypography.mono(
                      mode == kind ? context.ink : context.muted, 9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Blank extends StatelessWidget {
  const _Blank({
    required this.mode,
    required this.forBroadcast,
    required this.onPrompt,
  });

  final AiKind mode;
  final bool forBroadcast;
  final ValueChanged<String> onPrompt;

  /// Openers for the blank page. They are the hardest thing to write from
  /// nothing, so the screen offers a few rather than an empty field.
  static const _prompts = [
    'Apologize for being distant',
    'Wish them goodnight',
    'Plan a surprise weekend',
    "Tell them I'm proud of them",
  ];

  @override
  Widget build(BuildContext context) {
    if (mode == AiKind.image) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Text(AppStrings.describeImage,
              textAlign: TextAlign.center,
              style: AppTypography.display(
                  context.ink.withValues(alpha: 0.35), 26)),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 24),
      child: Column(
        children: [
          Text('Tell me what\u2019s on your mind.',
              textAlign: TextAlign.center,
              style: AppTypography.display(context.ink, 26)),
          const SizedBox(height: 12),
          Text(
            forBroadcast
                ? "I'LL DRAFT A FEW WAYS TO SAY IT TO EVERYONE."
                : "I'LL DRAFT A FEW WAYS TO SAY IT.",
            textAlign: TextAlign.center,
            style: AppTypography.mono(context.muted, 9),
          ),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final prompt in _prompts)
                GestureDetector(
                  onTap: () => onPrompt(prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: context.ink.withValues(alpha: 0.08)),
                    ),
                    child: Text(prompt,
                        style: context.text.bodySmall
                            ?.copyWith(color: context.ink)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TurnView extends StatelessWidget {
  const _TurnView({
    required this.turn,
    required this.onChoose,
    required this.onSendPicture,
  });

  final AiTurn turn;
  final ValueChanged<String> onChoose;
  final ValueChanged<String> onSendPicture;

  @override
  Widget build(BuildContext context) {
    return switch (turn) {
      AiAsk(:final text) => _Bubble.mine(text: text),
      AiThinking(:final stage) => _Bubble.theirs(child: _Thinking(stage: stage)),
      AiTrouble(:final message) => _Bubble.theirs(
          child: Text(message,
              style: TextStyle(fontSize: 13.5, color: context.muted)),
        ),
      AiDrafts(:final drafts, :final note) => _Bubble.theirs(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (note.isNotEmpty) ...[
                Text(note,
                    style: TextStyle(
                        fontSize: 13.5, height: 1.45, color: context.ink)),
                const SizedBox(height: 12),
              ],
              for (final draft in drafts)
                _DraftCard(text: draft, onTap: () => onChoose(draft)),
            ],
          ),
        ),
      AiPicture(:final url, :final prompt) => _Bubble.theirs(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppNetworkImage(source: url, radius: 0),
                ),
              ),
              const SizedBox(height: 10),
              Text(prompt,
                  style: TextStyle(fontSize: 12.5, color: context.muted)),
              const SizedBox(height: 10),
              _DraftCard(
                text: 'Send the image',
                label: 'SEND  →',
                onTap: url.isEmpty ? null : () => onSendPicture(url),
              ),
            ],
          ),
        ),
    };
  }
}

/// Your words on the right in the room's ember; SpaceAI's on the left in a
/// quiet panel — the same shape as the room, so the two read as one app.
class _Bubble extends StatelessWidget {
  const _Bubble._({this.text, this.child, required this.mine});

  factory _Bubble.mine({required String text}) =>
      _Bubble._(text: text, mine: true);

  factory _Bubble.theirs({required Widget child}) =>
      _Bubble._(mine: false, child: child);

  final String? text;
  final Widget? child;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.86,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            decoration: BoxDecoration(
              color: mine
                  ? context.colors.primary
                  : context.ink.withValues(alpha: 0.055),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(mine ? 20 : 6),
                bottomRight: Radius.circular(mine ? 6 : 20),
              ),
            ),
            child: child ??
                Text(text!,
                    style: const TextStyle(
                        fontSize: 14, height: 1.45, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.text, this.label = 'SEND  →', this.onTap});

  final String text;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text, style: AppTypography.display(context.ink, 16)),
                const SizedBox(height: 7),
                Text(label, style: AppTypography.mono(context.muted, 9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots breathing, so a slow model still feels like someone thinking.
class _Thinking extends StatefulWidget {
  const _Thinking({required this.stage});

  final String stage;

  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Opacity(
                    // Each dot trails the one before it by a third of a cycle.
                    opacity:
                        0.25 + 0.75 * (((_pulse.value + i / 3) % 1) < 0.5 ? 1 : 0),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: context.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(widget.stage,
              style: AppTypography.display(context.muted, 15)),
        ),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    required this.busy,
    required this.onSend,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border:
            Border(top: BorderSide(color: context.ink.withValues(alpha: 0.06))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            // A true pill, not the app's default 16px-radius field — this is
            // a conversation, so it reads as one the way a chat app's does.
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: context.ink.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: controller,
                maxLines: 1,
                enabled: !busy,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSend(),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: hint,
                  hintMaxLines: 1,
                  isDense: true,
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: hasText && !busy ? onSend : null,
            style: IconButton.styleFrom(
              backgroundColor: hasText && !busy
                  ? context.ink
                  : context.ink.withValues(alpha: 0.15),
              minimumSize: const Size(46, 46),
            ),
            icon: Icon(Icons.arrow_forward_rounded,
                size: 20, color: context.theme.scaffoldBackgroundColor),
          ),
        ],
      ),
    );
  }
}
