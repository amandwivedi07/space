import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/helpers/validators.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Collects a URL and an optional comment. Returns (url, comment).
class LinkDialog extends StatefulWidget {
  const LinkDialog({super.key});

  static Future<(String, String)?> show(BuildContext context) =>
      AppBottomSheet.show<(String, String)>(
        context,
        eyebrow: 'A link',
        title: AppStrings.pasteALink,
        child: const LinkDialog(),
      );

  @override
  State<LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _comment = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((_url.text.trim(), _comment.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _url,
            hint: 'https://…',
            keyboardType: TextInputType.url,
            validator: Validators.url,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _comment,
            hint: 'Add a comment on top…',
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Send it', expanded: true, onPressed: _submit),
        ],
      ),
    );
  }
}
