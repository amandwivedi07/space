import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:space_flutter/core/theme/app_theme.dart';
import 'package:space_flutter/features/chat/data/models/space_card.dart';
import 'package:space_flutter/features/chat/presentation/widgets/card_content.dart';

/// The voice card has overflowed twice: once horizontally, when the waveform
/// was a fixed 260pt inside a narrower card, and once vertically, when the
/// whole transcript was laid out invisibly ahead of playback. Both only showed
/// up on a device. These pin the layout at sizes that reproduced them.
void main() {
  SpaceCard voice({required String body, int seconds = 30}) => SpaceCard(
        id: 'card-abc-123',
        roomId: 'room-1',
        senderId: 'me',
        type: CardType.voice,
        body: body,
        mediaPath: 'https://example.invalid/voice.wav',
        durationSec: seconds,
        sentAt: DateTime(2026, 8, 12),
      );

  Widget host(SpaceCard card, {double width = 300, double height = 420}) =>
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: SingleChildScrollView(
                  child: CardContent(card: card),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('an unplayed note renders no transcript and does not overflow',
      (tester) async {
    // A thirty-second note: the transcript that produced the 20px overflow.
    const long = 'hello hello testing one two three this is a much longer '
        'voice note that goes on for quite a while and keeps going so that '
        'the transcript is genuinely long enough to fill the card';

    await tester.pumpWidget(host(voice(body: long)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Nothing has played, so not a word of the transcript is on screen.
    expect(find.textContaining('hello'), findsNothing);
    // The duration label is, though — the card is still a voice note.
    expect(find.textContaining('VOICE'), findsOneWidget);
  });

  testWidgets('stays within a narrow card', (tester) async {
    await tester.pumpWidget(host(voice(body: 'short one'), width: 220));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty transcript is fine — a note need not have words',
      (tester) async {
    await tester.pumpWidget(host(voice(body: '')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('VOICE'), findsOneWidget);
  });
}
