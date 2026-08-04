import 'package:flutter_test/flutter_test.dart';
import 'package:space_flutter/core/constants/fade_options.dart';

void main() {
  test('roomClause never repeats "after seen"', () {
    for (final option in FadeOption.values) {
      final line = 'CARDS ${option.roomClause} · KEEP TO REMEMBER';
      expect('AFTER SEEN'.allMatches(line).length, lessThan(2),
          reason: 'doubled up for ${option.name}: $line');
    }
  });

  test('roomClause reads as a sentence for each kind of timer', () {
    expect(FadeOption.afterSeen.roomClause, 'FADE AFTER SEEN');
    expect(FadeOption.viewOnce.roomClause, 'ARE SEEN ONCE, THEN GONE');
    expect(FadeOption.m1.roomClause, 'FADE 1 MINUTE AFTER SEEN');
  });
}
