import 'package:flutter/material.dart';

import '../extensions/context_x.dart';

/// Rounded search input used on home and pickers.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.autofocus = false,
    this.onClose,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.muted),
        suffixIcon: onClose == null
            ? null
            : IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, size: 18, color: context.muted),
              ),
      ),
    );
  }
}
