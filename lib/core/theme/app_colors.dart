import 'package:flutter/material.dart';

/// Space colour tokens for the two moods:
/// "Warm paper" (light) and "Quiet night" (dark).
class AppColors {
  AppColors._();

  // Warm paper (light).
  static const paper = Color(0xFFF6F3EC);
  static const surfaceLight = Color(0xFFFDFBF6);
  static const ink = Color(0xFF2B2620);
  static const mutedLight = Color(0xFF8A8175);
  static const lineLight = Color(0x0F000000);
  static const ember = Color(0xFFB05C3F);
  static const emberSoft = Color(0xFFEFB794);

  // Quiet night (dark).
  static const night = Color(0xFF171512);
  static const surfaceDark = Color(0xFF211E1A);
  static const inkDark = Color(0xFFE8E3DA);
  static const mutedDark = Color(0xFF9A938A);
  static const lineDark = Color(0x14FFFFFF);

  // Presence.
  static const presenceHere = Color(0xFF5E8C61);
  static const presenceRecent = Color(0xFFC9A86A);
  static const presenceAway = Color(0xFFB9B2A6);

  // Feedback.
  static const danger = Color(0xFFA84A42);
  static const success = Color(0xFF5E8C61);
}
