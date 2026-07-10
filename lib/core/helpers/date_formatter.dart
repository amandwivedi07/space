import 'package:intl/intl.dart';

/// Date/time formatting helpers.
class DateFormatter {
  DateFormatter._();

  static final _time = DateFormat('h:mm a');
  static final _day = DateFormat('EEE, MMM d');

  /// "4:32 PM" for today, otherwise "Tue, Mar 4".
  static String cardStamp(DateTime dt) {
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    return sameDay ? _time.format(dt) : _day.format(dt);
  }

  /// mm:ss for recordings and countdowns.
  static String clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Compact remaining-time label: "58s", "12m", "1h".
  static String remaining(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    return '${d.inHours}h';
  }
}
