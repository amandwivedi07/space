import 'package:flutter_test/flutter_test.dart';

/// Mirrors the reveal maths in _RevealingTranscript: how many words have been
/// "spoken" by a given point through the note.
int spokenCount(String transcript, double progress) {
  final words = transcript.split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return 0;
  return (progress * words.length).ceil().clamp(0, words.length);
}

void main() {
  const line = 'hello hello what is up my friend';   // 7 words

  group('transcript reveal', () {
    test('nothing is shown before playback starts', () {
      expect(spokenCount(line, 0), 0);
    });

    test('the first word appears as soon as playback starts', () {
      // Rounding up matters: with floor(), the card would sit blank for a
      // whole word-slot after the audio had audibly begun.
      expect(spokenCount(line, 0.01), 1);
    });

    test('reveals proportionally through the note', () {
      expect(spokenCount(line, 0.5), 4);
      expect(spokenCount(line, 1.0), 7);
    });

    test('never exceeds the words available', () {
      expect(spokenCount(line, 1.4), 7);
      expect(spokenCount(line, 99), 7);
    });

    test('is monotonic — a word never un-reveals as playback advances', () {
      var previous = 0;
      for (var p = 0.0; p <= 1.0; p += 0.02) {
        final now = spokenCount(line, p);
        expect(now, greaterThanOrEqualTo(previous),
            reason: 'went backwards at progress $p');
        previous = now;
      }
    });

    test('collapses runs of whitespace rather than revealing empties', () {
      expect(spokenCount('one   two \n three', 1.0), 3);
    });

    test('an empty transcript reveals nothing at any progress', () {
      expect(spokenCount('', 0), 0);
      expect(spokenCount('   ', 1), 0);
    });

    test('a one-word note is fully revealed the moment it starts', () {
      expect(spokenCount('hey', 0.01), 1);
    });
  });
}
