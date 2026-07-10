import 'package:flutter/material.dart';

/// Shorthand access to theme + media query values from a BuildContext.
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  bool get isDark => theme.brightness == Brightness.dark;

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  Color get ink => colors.onSurface;
  Color get muted => text.bodySmall?.color ?? colors.onSurfaceVariant;
}
