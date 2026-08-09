import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Space type system: Space Grotesk (display), DM Sans (body) and
/// JetBrains Mono (small uppercase labels).
///
/// The display face used to be Playfair Display in italic — an editorial,
/// literary voice. The app now speaks in Space Grotesk: still characterful,
/// but upright and geometric, so a name set over a photograph reads as a
/// label on the image rather than a pull quote beside it.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color ink, Color muted) {
    final body = GoogleFonts.dmSansTextTheme();
    return body.copyWith(
      displayLarge: display(ink, 34),
      displayMedium: display(ink, 28),
      displaySmall: display(ink, 22),
      headlineMedium: display(ink, 20),
      titleLarge: GoogleFonts.dmSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: ink),
      titleMedium: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      titleSmall: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: ink),
      bodyLarge: GoogleFonts.dmSans(fontSize: 16, height: 1.45, color: ink),
      bodyMedium: GoogleFonts.dmSans(fontSize: 14, height: 1.45, color: ink),
      bodySmall: GoogleFonts.dmSans(fontSize: 12, height: 1.4, color: muted),
      labelLarge: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w500, color: ink),
      labelSmall: mono(muted, 10),
    );
  }

  /// Display style — Space Grotesk, bold and tightly led. The negative
  /// letter-spacing is what stops the big home headline from looking airy.
  static TextStyle display(Color color, double size) => GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.5,
        color: color,
      );

  /// Small uppercase mono label ("A NEW SPACE", "HERE NOW").
  static TextStyle mono(Color color, double size) => GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.2,
        color: color,
      );
}
