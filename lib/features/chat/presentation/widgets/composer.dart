import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/fade_options.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/audio_convert_service.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../space_ai/presentation/screens/space_ai_screen.dart';
import '../viewmodels/room_viewmodel.dart';
import 'attach_sheet.dart';
import 'fade_timer_sheet.dart';
import 'link_dialog.dart';
import 'voice_record_button.dart';

/// The card composer: text, attachments, voice, SpaceAI and the fade chip.
class Composer extends ConsumerStatefulWidget {
  const Composer({super.key, required this.roomId, required this.hint});

  final String roomId;
  final String hint;

  /// Opens SpaceAI and handles the outcome. Drafts SEND DIRECTLY (like the
  /// web app) — the card carries the "Sent with SpaceAI." mark.
  static Future<void> openSpaceAi(
    BuildContext context,
    WidgetRef ref,
    String roomId, {
    String? replyTo,
    String? replyToName,
  }) async {
    final outcome = await SpaceAiScreen.open(
      context,
      replyTo: replyTo,
      replyToName: replyToName,
    );
    if (outcome == null || !context.mounted) return;
    final vm = ref.read(roomViewModelProvider(roomId).notifier);
    switch (outcome) {
      case AiDraftChosen(:final text):
        vm.sendAiText(text);
        AppToast.show(context, AppStrings.sentWithAi, icon: Icons.auto_awesome);
      case AiMediaReady(:final url):
        if (url.isEmpty) {
          AppToast.show(context, "That picture didn't come through");
          return;
        }
        vm.sendAiImage(url);
        AppToast.show(context, AppStrings.aiImageSent);
    }
  }

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final _controller = TextEditingController();
  bool _voiceRecording = false;
  int _voiceElapsed = 0;
  String _voiceTranscript = '';

  RoomViewModel get _vm =>
      ref.read(roomViewModelProvider(widget.roomId).notifier);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendText() {
    _vm.sendText(_controller.text);
    _controller.clear();
    setState(() {});
  }

  Future<void> _pickFade() async {
    final current = ref.read(roomViewModelProvider(widget.roomId)).fade;
    final chosen = await FadeTimerSheet.show(context, current);
    if (chosen != null) _vm.setFade(chosen);
  }

  Future<void> _attach() async {
    final choice = await AttachSheet.show(context);
    if (choice == null || !mounted) return;
    final picker = ref.read(mediaPickerProvider);
    switch (choice) {
      case AttachChoice.camera:
        final path = await picker.pickImage(fromCamera: true);
        if (path != null) await _uploadAndSend(path, isVideo: false);
      case AttachChoice.recordVideo:
        final path = await picker.pickVideo(fromCamera: true);
        if (path != null) await _uploadAndSend(path, isVideo: true);
      case AttachChoice.photo:
        final path = await picker.pickImage();
        if (path != null) await _uploadAndSend(path, isVideo: false);
      case AttachChoice.video:
        final path = await picker.pickVideo();
        if (path != null) await _uploadAndSend(path, isVideo: true);
      case AttachChoice.link:
        if (!mounted) return;
        final link = await LinkDialog.show(context);
        if (link != null) {
          _sendWithToast(
            () => _vm.sendLink(link.$1, comment: link.$2),
            AppStrings.linkSent,
          );
        }
    }
  }

  /// Uploads the picked file to POST /media, then sends the card with its URL.
  Future<void> _uploadAndSend(String path, {required bool isVideo}) async {
    if (mounted) {
      AppToast.show(context, 'Sending…', icon: Icons.cloud_upload_outlined);
    }
    try {
      final url = await ref.read(apiClientProvider).upload(path);
      isVideo ? _vm.sendVideo(url) : _vm.sendPhoto(url);
      if (mounted) {
        AppToast.show(
          context,
          isVideo ? AppStrings.videoSent : AppStrings.photoSent,
        );
      }
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  /// Uploads the recorded audio, then sends the voice card with its URL.
  Future<void> _uploadAndSendVoice(
    String path,
    int seconds,
    String transcript,
  ) async {
    setState(() {
      _voiceRecording = false;
      _voiceElapsed = 0;
      _voiceTranscript = '';
    });
    try {
      final uploadPath =
          await ref.read(audioConvertProvider).forUpload(path);
      final url = await ref.read(apiClientProvider).upload(uploadPath);
      _vm.sendVoice(
        seconds,
        url: url,
        transcript: transcript,
      );
      if (mounted) AppToast.show(context, AppStrings.voiceNoteSent);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  void _onVoiceStateChanged(bool recording, int elapsed, String transcript) {
    setState(() {
      _voiceRecording = recording;
      _voiceElapsed = elapsed;
      _voiceTranscript = transcript;
    });
  }

  void _sendWithToast(VoidCallback send, String message) {
    send();
    if (mounted) AppToast.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final fade = ref.watch(
      roomViewModelProvider(widget.roomId).select((s) => s.fade),
    );
    final hasText = _controller.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            top: BorderSide(color: context.ink.withValues(alpha: 0.06)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_voiceRecording)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecordingPreview(
                  elapsedSec: _voiceElapsed,
                  transcript: _voiceTranscript,
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _attach,
                  tooltip: 'Attach',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: context.ink,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  // A true pill, not the app's default 16px-radius field —
                  // matches the shape SpaceAI's own input already uses, so
                  // the two don't disagree about what a text field looks like.
                  // IconButton's own 48x48 hit box was already padding the
                  // left of this row before the pill's own inset ever
                  // started, which is what read as "too much space".
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
                            controller: _controller,
                            // One line, always. A field that grows as you type
                            // pushed the whole rail around and read as a form.
                            maxLines: 5,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _sendText(),
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: widget.hint,
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
                        // How long it lasts belongs to the message being
                        // written, so it rides inside the field rather than
                        // sitting on a line of its own above it.
                        const SizedBox(width: 8),
                        _FadeChip(fade: fade, onTap: _pickFade),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasText)
                  IconButton.filled(
                    onPressed: _sendText,
                    style: IconButton.styleFrom(backgroundColor: context.ink),
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                      color: context.theme.scaffoldBackgroundColor,
                      size: 20,
                    ),
                  )
                else
                  VoiceRecordButton(
                    onRecorded: _uploadAndSendVoice,
                    onStateChanged: _onVoiceStateChanged,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Live whisper preview while the mic is open — matches the web recording card.
class _RecordingPreview extends StatelessWidget {
  const _RecordingPreview({
    required this.elapsedSec,
    required this.transcript,
  });

  final int elapsedSec;
  final String transcript;

  @override
  Widget build(BuildContext context) {
    final clock = '${elapsedSec ~/ 60}:${(elapsedSec % 60).toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppStrings.recording} · $clock',
                style: AppTypography.mono(context.muted, 9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LiveTranscript(transcript: transcript),
        ],
      ),
    );
  }
}

/// The transcript as it is being spoken, with the last word dimmed.
///
/// The recogniser revises its tail as it hears more — "win" becomes "windy"
/// becomes "Wednesday" — so the final word is the one most likely to change.
/// Dimming it says so without the text appearing to stutter, and makes the
/// panel read as still-listening rather than finished.
class _LiveTranscript extends StatelessWidget {
  const _LiveTranscript({required this.transcript});

  final String transcript;

  @override
  Widget build(BuildContext context) {
    final base = context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    if (transcript.isEmpty) {
      return Text('…', style: base?.copyWith(color: context.muted));
    }

    // Split on the last space rather than tokenising: everything before it is
    // settled, and only the trailing word is in flight.
    final cut = transcript.trimRight().lastIndexOf(' ');
    if (cut <= 0) {
      return Text(transcript, style: base?.copyWith(color: context.muted));
    }

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: transcript.substring(0, cut)),
          TextSpan(
            text: transcript.substring(cut),
            style: base?.copyWith(color: context.muted),
          ),
        ],
      ),
    );
  }
}

/// The fade timer, as a chip inside the field: "⏱ 60M". Compact by design —
/// it sits in the same pill as the text, so the full sentence ("fades 60
/// minutes after seen") is left to the sheet it opens.
class _FadeChip extends StatelessWidget {
  const _FadeChip({required this.fade, required this.onTap});

  final FadeOption fade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.ink.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: context.muted),
            const SizedBox(width: 5),
            Text(fade.chipLabel, style: AppTypography.mono(context.muted, 8.5)),
          ],
        ),
      ),
    );
  }
}
