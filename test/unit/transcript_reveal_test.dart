import 'package:flutter_test/flutter_test.dart';

/// Mirrors the pacing in _RevealingTranscript: words are revealed at natural
/// speaking rate, or faster if the note is denser than that.
const naturalWps = 2.6;
const lead = Duration(milliseconds: 250);

int spokenAt(String transcript, Duration elapsed, Duration total) {
  final words = transcript.split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return 0;
  // At rest the lead must not apply, or an unplayed note shows its first word.
  if (elapsed <= Duration.zero) return 0;
  final seconds = (elapsed + lead).inMilliseconds / 1000;
  final totalSeconds = total.inMilliseconds / 1000;
  final even = totalSeconds > 0 ? words.length / totalSeconds : 0.0;
  final rate = even > naturalWps ? even : naturalWps;
  return (seconds * rate).ceil().clamp(0, words.length);
}

void main() {
  group('reveal pacing', () {
    // The three real notes from production that exposed the lag. Each has far
    // more recording than speech, because people keep recording after they
    // stop talking.
    test('"latest update" — 2 words in an 8 second recording', () {
      const t = 'latest update';
      const total = Duration(seconds: 8);
      // Both words are out within a second, not spread across eight.
      expect(spokenAt(t, const Duration(milliseconds: 500), total), 2);
      // The old even spread would have shown only the first word until 4s.
      expect(spokenAt(t, const Duration(seconds: 4), total), 2);
    });

    test('"Hello hello hello" — 3 words in 6 seconds', () {
      const t = 'Hello hello hello';
      const total = Duration(seconds: 6);
      expect(spokenAt(t, const Duration(milliseconds: 800), total), 3);
    });

    test('8 words in 5 seconds keeps up with the voice', () {
      const t = 'the seems to skip the first few words';
      const total = Duration(seconds: 5);
      // By 2s a speaker is ~5 words in; the reveal must be at least there.
      expect(spokenAt(t, const Duration(seconds: 2), total),
          greaterThanOrEqualTo(5));
    });

    test('the first word is up almost immediately once playing', () {
      // The lead covers the recogniser's start-up lag, which is what made the
      // opening words audible before they were readable.
      expect(
          spokenAt('one two three', const Duration(milliseconds: 50),
              const Duration(seconds: 5)),
          greaterThanOrEqualTo(1));
    });

    test('nothing shows before playback starts', () {
      // Guards the compact card: at rest the lead must not leak a word out.
      expect(spokenAt('one two three', Duration.zero, const Duration(seconds: 5)),
          0);
    });

    test('a dense note is paced by the note, not by the natural rate', () {
      // 40 words in 8s is 5 words/sec — faster than natural speech, so the
      // even spread is the one that keeps up.
      final t = List.filled(40, 'word').join(' ');
      const total = Duration(seconds: 8);
      expect(spokenAt(t, const Duration(seconds: 4), total),
          greaterThanOrEqualTo(20));
    });

    test('never runs past the words available', () {
      const t = 'one two three';
      expect(spokenAt(t, const Duration(seconds: 60), const Duration(seconds: 6)), 3);
    });

    test('is monotonic', () {
      const t = 'one two three four five six seven eight';
      const total = Duration(seconds: 6);
      var previous = 0;
      for (var ms = 0; ms <= 6000; ms += 100) {
        final now = spokenAt(t, Duration(milliseconds: ms), total);
        expect(now, greaterThanOrEqualTo(previous), reason: 'went back at $ms');
        previous = now;
      }
    });

    test('an empty transcript reveals nothing', () {
      expect(spokenAt('', const Duration(seconds: 2), const Duration(seconds: 5)), 0);
      expect(spokenAt('   ', const Duration(seconds: 2), const Duration(seconds: 5)), 0);
    });
  });
}
