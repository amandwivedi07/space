import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_typography.dart';

/// Asks for a new name for a circle.
///
/// Returns the trimmed name, or null if the reader backed out. Save stays
/// disabled while the field is empty or unchanged, so the dialog cannot be
/// used to send a request that would do nothing.
class RenameCircleDialog extends StatefulWidget {
  const RenameCircleDialog({super.key, required this.current});

  final String current;

  static Future<String?> show(BuildContext context, String current) =>
      showDialog<String>(
        context: context,
        builder: (_) => RenameCircleDialog(current: current),
      );

  @override
  State<RenameCircleDialog> createState() => _RenameCircleDialogState();
}

class _RenameCircleDialogState extends State<RenameCircleDialog> {
  static const _maxLength = 40;

  late final TextEditingController _controller =
      TextEditingController(text: widget.current);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Mirrors the server: trimmed, with internal runs of whitespace collapsed.
  /// Comparing the collapsed form means "A small   circle" counts as unchanged.
  String get _cleaned => _controller.text.trim().split(RegExp(r'\s+')).join(' ');

  /// Counted in runes, because that is what the server counts. Flutter's
  /// maxLength counts grapheme clusters, so 40 emoji reads as "40/40" here and
  /// arrives as 200 characters there — the app would enable Save on a name the
  /// server then refuses.
  int get _length => _cleaned.runes.length;

  bool get _canSave =>
      _cleaned.isNotEmpty && _cleaned != widget.current && _length <= _maxLength;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      title: Text('Rename circle',
          style: AppTypography.display(context.ink, 21)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EVERYONE IN IT SEES THE NEW NAME',
              style: AppTypography.mono(context.muted, 8.5)),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            // Newlines would survive the trim as internal whitespace and make
            // a one-line name two.
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_canSave) Navigator.of(context).pop(_cleaned);
            },
            decoration: InputDecoration(
              hintText: 'A small circle',
              filled: true,
              fillColor: context.ink.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              // Our own counter, so it agrees with the server's limit rather
              // than with Flutter's idea of a character.
              counterText: '$_length/$_maxLength',
              counterStyle: AppTypography.mono(
                  _length > _maxLength ? context.colors.error : context.muted,
                  8.5),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: TextStyle(color: context.muted)),
        ),
        FilledButton(
          onPressed: _canSave ? () => Navigator.of(context).pop(_cleaned) : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
