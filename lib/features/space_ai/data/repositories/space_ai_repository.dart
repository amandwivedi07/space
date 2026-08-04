import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/result.dart';
import '../models/ai_result.dart';

/// SpaceAI contract — drafting help and image generation, both server-side.
abstract class SpaceAiRepository {
  Future<Result<AiResult>> draftMessage(String prompt);
  Future<Result<AiResult>> generateImage(String prompt);

  /// False when the server has no model credentials, so the UI can stay quiet
  /// instead of offering something that will fail.
  Future<bool> available();
}

/// Talks to the backend, which holds the Azure credentials — no model key ever
/// reaches the client.
class ApiSpaceAiRepository implements SpaceAiRepository {
  ApiSpaceAiRepository(this._client);

  final ApiClient _client;

  bool? _enabled; // cached: the answer only changes on redeploy

  @override
  Future<bool> available() async {
    if (_enabled != null) return _enabled!;
    try {
      final data = await _client.get('/ai/status') as Map<String, dynamic>;
      return _enabled = data['enabled'] as bool? ?? false;
    } on ApiException {
      return false; // a network blip is not cached as "off"
    }
  }

  @override
  Future<Result<AiResult>> draftMessage(String prompt) async {
    try {
      final data = await _client.post(
        '/ai/drafts',
        body: {'prompt': prompt},
        receiveTimeout: const Duration(seconds: 60),
      ) as Map<String, dynamic>;
      final drafts =
          (data['drafts'] as List? ?? const []).map((d) => d.toString()).toList();
      if (drafts.isEmpty) {
        return const Failure(
            'SpaceAI came back empty. Try saying it differently.');
      }
      return Success(AiResult(
        kind: AiKind.draft,
        prompt: prompt,
        drafts: drafts,
        note: data['note'] as String? ?? '',
      ));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }

  @override
  Future<Result<AiResult>> generateImage(String prompt) async {
    try {
      // The model takes 30-60s to draw; the default 20s read timeout would
      // abandon a request the server goes on to complete successfully.
      final data = await _client.post(
        '/ai/image',
        body: {'prompt': prompt},
        receiveTimeout: const Duration(seconds: 150),
      ) as Map<String, dynamic>;
      final url = data['media_url'] as String? ?? '';
      if (url.isEmpty) return const Failure('SpaceAI did not return a picture.');
      return Success(AiResult(kind: AiKind.image, prompt: prompt, url: url));
    } on ApiException catch (e) {
      return Failure(e.message);
    }
  }
}

final spaceAiRepositoryProvider = Provider<SpaceAiRepository>(
  (ref) => ApiSpaceAiRepository(ref.watch(apiClientProvider)),
);

/// Whether the server has model credentials. The composer hides SpaceAI when
/// it doesn't, rather than offering a button that always fails.
final spaceAiAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(spaceAiRepositoryProvider).available(),
);
