import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../space_ai/presentation/widgets/space_ai_sheet.dart';
import '../../../space_ai/data/repositories/space_ai_repository.dart';
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
      BuildContext context, WidgetRef ref, String roomId) async {
    final outcome = await SpaceAiSheet.show(context);
    if (outcome == null || !context.mounted) return;
    final vm = ref.read(roomViewModelProvider(roomId).notifier);
    switch (outcome) {
      case AiDraftChosen(:final text):
        vm.sendAiText(text);
        AppToast.show(context, AppStrings.sentWithAi,
            icon: Icons.auto_awesome);
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
              () => _vm.sendLink(link.$1, comment: link.$2), AppStrings.linkSent);
        }
    }
  }

  /// Uploads the picked file to POST /media, then sends the card with its URL.
  Future<void> _uploadAndSend(String path, {required bool isVideo}) async {
    if (mounted) AppToast.show(context, 'Sending…', icon: Icons.cloud_upload_outlined);
    try {
      final url = await ref.read(apiClientProvider).upload(path);
      isVideo ? _vm.sendVideo(url) : _vm.sendPhoto(url);
      if (mounted) {
        AppToast.show(
            context, isVideo ? AppStrings.videoSent : AppStrings.photoSent);
      }
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  /// Uploads the recorded audio, then sends the voice card with its URL.
  Future<void> _uploadAndSendVoice(String path, int seconds) async {
    try {
      final url = await ref.read(apiClientProvider).upload(path);
      _vm.sendVoice(seconds, url: url);
      if (mounted) AppToast.show(context, AppStrings.voiceNoteSent);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, e.message);
    }
  }

  Future<void> _openAi() => Composer.openSpaceAi(context, ref, widget.roomId);

  void _sendWithToast(VoidCallback send, String message) {
    send();
    if (mounted) AppToast.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final fade =
        ref.watch(roomViewModelProvider(widget.roomId).select((s) => s.fade));
    final hasText = _controller.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border:
              Border(top: BorderSide(color: context.ink.withValues(alpha: 0.06))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickFade,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_bottom_rounded,
                      size: 12, color: context.muted),
                  const SizedBox(width: 4),
                  Text(fade.sentenceLabel.toLowerCase(),
                      style: context.text.bodySmall),
                  Icon(Icons.expand_more_rounded,
                      size: 14, color: context.muted),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _attach,
                  tooltip: 'Attach',
                  icon: Icon(Icons.add_circle_outline_rounded,
                      color: context.ink),
                ),
                // Hidden entirely when the server has no model credentials.
                if (ref.watch(spaceAiAvailableProvider).valueOrNull ?? false)
                  IconButton(
                    onPressed: _openAi,
                    tooltip: AppStrings.spaceAi,
                    icon: Icon(Icons.auto_awesome_outlined, color: context.ink),
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: AppConstants.maxComposerLines,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _sendText(),
                    decoration: InputDecoration(hintText: widget.hint),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasText)
                  IconButton.filled(
                    onPressed: _sendText,
                    style: IconButton.styleFrom(backgroundColor: context.ink),
                    icon: Icon(Icons.arrow_upward_rounded,
                        color: context.theme.scaffoldBackgroundColor, size: 20),
                  )
                else
                  VoiceRecordButton(onRecorded: _uploadAndSendVoice),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
