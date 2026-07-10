import 'dart:io';

import 'package:flutter/material.dart';

import '../extensions/context_x.dart';

/// Image loader that handles network URLs and local file paths with a
/// soft placeholder and graceful error fallback.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 16,
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  bool get _isNetwork => source.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: context.ink.withValues(alpha: 0.05),
      child: Icon(Icons.image_outlined, color: context.muted, size: 22),
    );

    Widget image;
    if (_isNetwork) {
      image = Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else {
      image = Image.file(
        File(source),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: image,
    );
  }
}
