import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/fade_options.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/result.dart';
import '../../../chat/data/models/space_card.dart';

/// One line on the recipient's home: who broadcast, and when.
class BroadcastFrom {
  const BroadcastFrom({
    required this.spaceId,
    required this.name,
    required this.avatarUrl,
    required this.sentAt,
    required this.unread,
  });

  final String spaceId;
  final String name;
  final String avatarUrl;
  final DateTime sentAt;
  final bool unread;
}

/// What came back from a broadcast: how far it actually reached. There is no
/// content here on purpose — the words now live in the cards it created and
/// fade with them, exactly like anything else in Space.
class BroadcastResult {
  const BroadcastResult({required this.id, required this.recipientCount});

  final String id;
  final int recipientCount;
}

/// Compose once, deliver into every space you share. The server decides the
/// audience — the client never sends a recipient list, so a broadcast can
/// never reach someone who has not accepted.
abstract class BroadcastRepository {
  /// How many people it would reach right now.
  Future<Result<int>> audience();

  Future<Result<BroadcastResult>> send({
    required String body,
    required FadeOption fade,
    bool aiGenerated = false,
  });

  /// Your own broadcasts, one card each — what the "everyone" room shows.
  Future<Result<List<SpaceCard>>> cards();

  /// Who has broadcast to you, latest per person.
  Future<Result<List<BroadcastFrom>>> inbox();
}

class ApiBroadcastRepository implements BroadcastRepository {
  ApiBroadcastRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<int>> audience() async {
    try {
      final data = await _client.get('/broadcasts/audience')
          as Map<String, dynamic>;
      return Success((data['count'] as num?)?.toInt() ?? 0);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<BroadcastResult>> send({
    required String body,
    required FadeOption fade,
    bool aiGenerated = false,
  }) async {
    try {
      final data = await _client.post('/broadcasts', body: {
        'type': 'text',
        'body': body,
        'fade': fade.name,
        'ai_generated': aiGenerated,
      }) as Map<String, dynamic>;
      return Success(BroadcastResult(
        id: data['id'] as String? ?? '',
        recipientCount: (data['recipient_count'] as num?)?.toInt() ?? 0,
      ));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<List<SpaceCard>>> cards() async {
    try {
      final data = await _client.get('/broadcasts/cards') as List<dynamic>;
      return Success([
        for (final raw in data.cast<Map<String, dynamic>>())
          SpaceCard(
            id: raw['id'] as String,
            roomId: 'broadcast',
            // Everything here is yours by definition — the endpoint only ever
            // returns the caller's own broadcasts.
            senderId: 'me',
            type: CardType.text,
            body: raw['body'] as String? ?? '',
            fade: FadeOption.fromId(raw['fade'] as String?),
            sentAt:
                DateTime.tryParse(raw['sent_at'] as String? ?? '')?.toLocal() ??
                    DateTime.now(),
            seenAt:
                DateTime.tryParse(raw['seen_at'] as String? ?? '')?.toLocal(),
            kept: raw['kept'] as bool? ?? false,
            keptAt:
                DateTime.tryParse(raw['kept_at'] as String? ?? '')?.toLocal(),
            aiGenerated: raw['ai_generated'] as bool? ?? false,
            reactions:
                List<String>.from(raw['reactions'] as List? ?? const []),
          ),
      ]);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<List<BroadcastFrom>>> inbox() async {
    try {
      final data = await _client.get('/broadcasts/inbox') as List<dynamic>;
      return Success([
        for (final raw in data.cast<Map<String, dynamic>>())
          BroadcastFrom(
            spaceId: raw['space_id'] as String,
            name: raw['name'] as String? ?? 'Someone',
            avatarUrl: raw['avatar_url'] as String? ?? '',
            sentAt:
                DateTime.tryParse(raw['sent_at'] as String? ?? '')?.toLocal() ??
                    DateTime.now(),
            unread: raw['unread'] as bool? ?? false,
          ),
      ]);
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}

final broadcastRepositoryProvider = Provider<BroadcastRepository>(
  (ref) => ApiBroadcastRepository(ref.watch(apiClientProvider)),
);

/// The audience, fetched fresh each time the composer opens — "everyone" must
/// never be a number the reader has to take on trust.
final broadcastAudienceProvider = FutureProvider.autoDispose<int>((ref) async {
  final result = await ref.watch(broadcastRepositoryProvider).audience();
  return result.when(success: (count) => count, failure: (_) => 0);
});

/// Who has broadcast to you. Refreshed with home, so a broadcast that has
/// faded stops being advertised.
final broadcastInboxProvider =
    FutureProvider.autoDispose<List<BroadcastFrom>>((ref) async {
  final result = await ref.watch(broadcastRepositoryProvider).inbox();
  return result.when(success: (rows) => rows, failure: (_) => const []);
});
