import 'dart:async';

/// Debounces rapid calls — used by search fields.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 250)});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
