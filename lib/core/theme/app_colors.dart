import 'package:flutter/material.dart';

/// Space colour tokens.
///
/// The palette is a single purple family in two moods. "Quiet night" is the
/// design of record — the tiles are photographs, and photographs only glow
/// against a dark ground. "Soft dawn" is its counterpart, derived at the same
/// hue and chroma with the lightness inverted, so the two read as one system
/// rather than two designs.
class AppColors {
  AppColors._();

  // Quiet night (dark) — the reference palette.
  static const night = Color(0xFF170E27);
  static const surfaceDark = Color(0xFF261A3A);
  static const inkDark = Color(0xFFFAF3F7);
  static const mutedDark = Color(0xFFC7AFC4);
  static const lineDark = Color(0x1FFAF3F7);
  static const secondaryDark = Color(0xFF36274E);

  // Soft dawn (light) — same hues, lightness inverted.
  static const paper = Color(0xFFF5F2FC);
  static const surfaceLight = Color(0xFFFEFDFF);
  static const ink = Color(0xFF1E142E);
  static const mutedLight = Color(0xFF72627C);
  static const lineLight = Color(0x1A1D1431);
  static const secondaryLight = Color(0xFFE6E2F2);

  /// Coral, not rust. It carries the accent on both moods, but a light ground
  /// needs the darker step to stay legible against near-white.
  static const ember = Color(0xFFFF747A);
  static const emberLight = Color(0xFFE14754);
  static const emberSoft = Color(0xFFFFB3B6);

  // Presence.
  static const presenceHere = Color(0xFF5FD08A);
  static const presenceRecent = Color(0xFFD9A45C);
  static const presenceAway = Color(0xFF8D82A0);

  // Feedback.
  static const danger = Color(0xFFE54056);
  static const dangerLight = Color(0xFFCC2443);
  static const success = Color(0xFF5FD08A);
}
