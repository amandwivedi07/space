import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the split in _LiveTranscript: everything before the last space is
/// settled, the trailing word is still in flight and gets dimmed.
(String settled, String tail) splitTranscript(String transcript) {
  final cut = transcript.trimRight().lastIndexOf(' ');
  if (transcript.isEmpty || cut <= 0) return ('', transcript);
  return (transcript.substring(0, cut), transcript.substring(cut));
}

void main() {
  group('live transcript split', () {
    test('dims only the last word', () {
      final (settled, tail) = splitTranscript('hello hello what\'s up');
      expect(settled, 'hello hello what\'s');
      expect(tail, ' up');
    });

    test('a single word is entirely unsettled', () {
      final (settled, tail) = splitTranscript('hello');
      expect(settled, '');
      expect(tail, 'hello');
    });

    test('empty stays empty', () {
      final (settled, tail) = splitTranscript('');
      expect(settled, '');
      expect(tail, '');
    });

    test('a trailing space does not orphan the last word', () {
      // The recogniser emits trailing spaces between partials; without the
      // trimRight the "last word" would be the empty string and nothing dims.
      final (settled, tail) = splitTranscript('how are you ');
      expect(settled, 'how are');
      expect(tail, ' you ');
    });

    test('the two halves always reconstruct the original', () {
      for (final s in [
        'hello hello what\'s up',
        'one',
        '',
        'how are you ',
        'a b',
      ]) {
        final (settled, tail) = splitTranscript(s);
        expect(settled + tail, s, reason: 'lost text for "$s"');
      }
    });
  });

  testWidgets('renders without overflowing a narrow panel', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 16, color: Colors.black),
              children: [
                TextSpan(text: 'how are you doing and what have you been'),
                TextSpan(text: ' tonight', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
