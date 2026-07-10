import 'package:flutter_test/flutter_test.dart';
import 'package:space_flutter/core/helpers/validators.dart';

void main() {
  group('Validators', () {
    test('name rejects empty and single characters', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Elena'), isNull);
    });

    test('handle is optional but format-checked', () {
      expect(Validators.handle(''), isNull);
      expect(Validators.handle('@elena'), isNull);
      expect(Validators.handle('elena_92'), isNull);
      expect(Validators.handle('bad handle!'), isNotNull);
    });

    test('url accepts bare domains and full urls', () {
      expect(Validators.url('example.com'), isNull);
      expect(Validators.url('https://example.com/a'), isNull);
      expect(Validators.url('not a link'), isNotNull);
      expect(Validators.url(''), isNotNull);
    });
  });
}
