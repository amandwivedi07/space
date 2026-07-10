import 'dart:math';

/// Collision-safe local id generation (replaced by server ids after API lands).
class IdGenerator {
  IdGenerator._();

  static final _random = Random();

  static String next([String prefix = 'id']) {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(0xFFFFF).toRadixString(36);
    return '$prefix-$time$salt';
  }

  /// Unique slug given existing ids: "elena", "elena-2", "elena-3"…
  static String uniqueSlug(String base, Iterable<String> existing) {
    final taken = existing.toSet();
    if (!taken.contains(base)) return base;
    var i = 2;
    while (taken.contains('$base-$i')) {
      i++;
    }
    return '$base-$i';
  }
}
