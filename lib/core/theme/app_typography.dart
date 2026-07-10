import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Space type system: Playfair Display (display, often italic),
/// Inter (body) and JetBrains Mono (small uppercase labels).
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color ink, Color muted) {
    final inter = GoogleFonts.interTextTheme();
    return inter.copyWith(
      displayLarge: display(ink, 34),
      displayMedium: display(ink, 28),
      displaySmall: display(ink, 22),
      headlineMedium: display(ink, 20),
      titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: ink),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      titleSmall: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: ink),
      bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.45, color: ink),
      bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.45, color: ink),
      bodySmall: GoogleFonts.inter(fontSize: 12, height: 1.4, color: muted),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, color: ink),
      labelSmall: mono(muted, 10),
    );
  }

  /// Editorial display style — Playfair Display italic.
  static TextStyle display(Color color, double size) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        height: 1.2,
        color: color,
      );

  /// Small uppercase mono label ("A NEW SPACE").
  static TextStyle mono(Color color, double size) => GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.2,
        color: color,
      );
}
