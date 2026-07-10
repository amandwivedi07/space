import '../../../../core/constants/fade_options.dart';
import '../models/space_card.dart';

/// Seeded opener cards so rooms feel lived-in. Replaced by history sync later.
class ChatSeedData {
  ChatSeedData._();

  static SpaceCard _card(
    String roomId,
    String senderId,
    String body, {
    int minutesAgo = 5,
    FadeOption fade = FadeOption.m5,
    CardType type = CardType.text,
  }) =>
      SpaceCard(
        id: 'seed-$roomId-${body.hashCode}',
        roomId: roomId,
        senderId: senderId,
        type: type,
        body: body,
        fade: fade,
        sentAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
      );

  static Map<String, List<SpaceCard>> rooms() => {
        'person:elena': [
          _card('person:elena', 'elena',
              'I found the tea house we talked about. It exists.',
              minutesAgo: 12, fade: FadeOption.m15),
          _card('person:elena', 'elena', 'Quiet corner table, our kind of light.',
              minutesAgo: 9, fade: FadeOption.m15),
        ],
        'person:noor': [
          _card('person:noor', 'noor', 'Are you awake?', minutesAgo: 4),
          _card('person:noor', 'noor',
              'The city is glowing tonight and nobody is looking.',
              minutesAgo: 3, fade: FadeOption.m5),
          _card('person:noor', 'noor', 'Come see.', minutesAgo: 2,
              fade: FadeOption.m5),
        ],
        'person:mira': [
          _card('person:mira', 'mira',
              'Finished the book. I need to sit with it a while.',
              minutesAgo: 40, fade: FadeOption.m45),
        ],
        'person:sofia': [
          _card('person:sofia', 'sofia', 'Waves at golden hour. Thought of you.',
              minutesAgo: 7, fade: FadeOption.m15),
        ],
        'person:dante': [
          _card('person:dante', 'dante', 'I have news.', minutesAgo: 6),
          _card('person:dante', 'dante', 'Good news.', minutesAgo: 5),
          _card('person:dante', 'dante', 'Call-me-when-you-can news.',
              minutesAgo: 5),
          _card('person:dante', 'dante', 'Okay it is a dog. We got a dog.',
              minutesAgo: 4, fade: FadeOption.m15),
        ],
        'person:marta': [
          _card('person:marta', 'marta', 'Steam rising from a cup of tea.',
              minutesAgo: 10, fade: FadeOption.m30),
        ],
        'person:leo': [
          _card('person:leo', 'leo', 'Rooftop at eight. Bring the good bread.',
              minutesAgo: 90, fade: FadeOption.m60),
          _card('person:leo', 'leo', 'And your telescope.', minutesAgo: 88,
              fade: FadeOption.m60),
        ],
        'circle:kyoto-trip': [
          _card('circle:kyoto-trip', 'elena',
              'Ryokan is booked. Two nights by the river.',
              minutesAgo: 25, fade: FadeOption.m45),
          _card('circle:kyoto-trip', 'julian',
              'I mapped the tea houses in walking order.',
              minutesAgo: 18, fade: FadeOption.m45),
          _card('circle:kyoto-trip', 'mira', 'October cannot come sooner.',
              minutesAgo: 14, fade: FadeOption.m45),
        ],
        'circle:sunday-supper': [
          _card('circle:sunday-supper', 'marta',
              'This week: hand-rolled pasta. Bring appetite and stories.',
              minutesAgo: 200, fade: FadeOption.m60),
        ],
      };
}
