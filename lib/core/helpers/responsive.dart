import 'package:flutter/material.dart';

/// Breakpoint-aware sizing helpers.
class Responsive {
  Responsive._();

  static const double phoneMax = 600;
  static const double tabletMax = 1024;

  static bool isPhone(BuildContext c) => MediaQuery.sizeOf(c).width < phoneMax;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    return w >= phoneMax && w < tabletMax;
  }

  static bool isWide(BuildContext c) => MediaQuery.sizeOf(c).width >= tabletMax;

  /// Value picker by form factor.
  static T value<T>(BuildContext c,
      {required T phone, T? tablet, T? wide}) {
    if (isWide(c)) return wide ?? tablet ?? phone;
    if (isTablet(c)) return tablet ?? phone;
    return phone;
  }

  /// Content max-width so wide screens keep the intimate column feel.
  static double contentWidth(BuildContext c) =>
      value(c, phone: MediaQuery.sizeOf(c).width, tablet: 560, wide: 640);

  /// Scale factor keyed off a 390pt reference width, clamped for sanity.
  static double scale(BuildContext c) =>
      (MediaQuery.sizeOf(c).width / 390).clamp(0.85, 1.25);
}
