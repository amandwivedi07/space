import 'package:flutter_test/flutter_test.dart';
import 'package:space_flutter/core/utils/handle.dart';

/// The same table the Go tests use. If the two drift, the app blocks something
/// the server accepts, or lets through something it refuses.
void main() {
  group('normalizeHandle', () {
    final cases = {
      'Aman': 'aman',
      '  aman  ': 'aman',
      '@aman': 'aman',
      ' @Aman ': 'aman',
      'AMAN.D': 'aman.d',
    };
    cases.forEach((input, want) {
      test('$input -> $want', () => expect(normalizeHandle(input), want));
    });
  });

  group('isValidHandle accepts', () {
    for (final h in [
      'ama', 'aman', 'aman.dwivedi', 'a_b', 'a-b', 'user123',
      'abcdefghijabcdefghijabcdefghij', // exactly 30
    ]) {
      test(h, () => expect(isValidHandle(h), isTrue));
    }
  });

  group('isValidHandle rejects', () {
    final cases = {
      '': 'empty',
      'ab': 'too short',
      'abcdefghijabcdefghijabcdefghijk': '31 characters',
      '.aman': 'leading dot',
      'aman.': 'trailing dot',
      '-aman': 'leading hyphen',
      'aman_': 'trailing underscore',
      '...': 'nothing but separators',
      'Aman': 'uppercase — must be normalised first',
      'aman dwivedi': 'a space',
      'aman@x': 'an at sign',
      'amán': 'a non-ascii letter',
    };
    cases.forEach((h, why) {
      test('$why: "$h"', () => expect(isValidHandle(h), isFalse));
    });
  });

  test('handleProblem is silent on an empty field', () {
    // Nothing typed is not yet a mistake — the message would nag.
    expect(handleProblem(''), isNull);
  });

  test('handleProblem explains a malformed handle', () {
    expect(handleProblem('.aman'), isNotNull);
  });
}
