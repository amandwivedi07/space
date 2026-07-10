import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Central logging — swap the sink for Crashlytics/Sentry later.
class Log {
  Log._();

  static void d(String message, {String tag = 'Space'}) {
    if (kDebugMode) developer.log(message, name: tag);
  }

  static void w(String message, {String tag = 'Space'}) {
    if (kDebugMode) developer.log('⚠ $message', name: tag);
  }

  static void e(String message,
      {Object? error, StackTrace? stack, String tag = 'Space'}) {
    developer.log(message, name: tag, error: error, stackTrace: stack);
  }
}
