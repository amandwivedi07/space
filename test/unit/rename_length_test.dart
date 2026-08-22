import 'package:flutter_test/flutter_test.dart';

/// Mirrors the dialog's gate. The server counts runes
/// (utf8.RuneCountInString); Flutter's maxLength counts grapheme clusters, and
/// the two disagree wildly on emoji.
String cleaned(String raw) => raw.trim().split(RegExp(r'\s+')).join(' ');
bool canSave(String raw, String current) {
  final c = cleaned(raw);
  return c.isNotEmpty && c != current && c.runes.length <= 40;
}

void main() {
  test('40 family emoji is 200 runes and must be refused', () {
    const family = '\u{1F469}‍\u{1F469}‍\u{1F467}';
    final name = family * 40;
    // Flutter's maxLength would count 40 grapheme clusters here and let it
    // through; the server counts runes and refuses it.
    expect(name.runes.length, greaterThan(40));
    expect(canSave(name, 'old'), isFalse);
  });

  test('40 plain characters is allowed', () {
    expect(canSave('a' * 40, 'old'), isTrue);
    expect(canSave('a' * 41, 'old'), isFalse);
  });

  test('40 accented characters is allowed — one rune each', () {
    expect(canSave('é' * 40, 'old'), isTrue);
  });

  test('unchanged or blank cannot be saved', () {
    expect(canSave('  Trio  ', 'Trio'), isFalse);
    expect(canSave('   ', 'Trio'), isFalse);
  });

  test('whitespace is collapsed before comparing', () {
    expect(canSave('A small   circle', 'A small circle'), isFalse);
  });
}
