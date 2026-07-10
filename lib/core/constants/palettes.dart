import 'package:flutter/material.dart';

/// Avatar gradient palettes, ported from the web app's oklch pairs.
class SpacePalette {
  const SpacePalette({
    required this.id,
    required this.label,
    required this.from,
    required this.to,
  });

  final String id;
  final String label;
  final Color from;
  final Color to;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [from, to],
      );

  static const ember =
      SpacePalette(id: 'ember', label: 'Ember', from: Color(0xFFEFB794), to: Color(0xFFB05C3F));
  static const rose =
      SpacePalette(id: 'rose', label: 'Rose', from: Color(0xFFF2C3CE), to: Color(0xFFA84A5A));
  static const tide =
      SpacePalette(id: 'tide', label: 'Tide', from: Color(0xFFA9C3D6), to: Color(0xFF3E6480));
  static const moss =
      SpacePalette(id: 'moss', label: 'Moss', from: Color(0xFFB7D6AE), to: Color(0xFF4E7D5E));
  static const sand =
      SpacePalette(id: 'sand', label: 'Sand', from: Color(0xFFE7D5B0), to: Color(0xFF8F7A4E));
  static const iris =
      SpacePalette(id: 'iris', label: 'Iris', from: Color(0xFFCBBEE8), to: Color(0xFF5D5490));

  static const all = [ember, rose, tide, moss, sand, iris];

  static SpacePalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => ember);
}
