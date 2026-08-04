/// What SpaceAI can hand back. Video needs a model deployment we do not
/// have, so it is deliberately absent rather than stubbed.
enum AiKind { draft, image }

/// A generated artefact: either phrasings to choose from, or a picture at
/// [url] that can be sent straight on as a card.
class AiResult {
  const AiResult({
    required this.kind,
    required this.prompt,
    this.drafts = const [],
    this.note = '',
    this.seed = 0,
    this.url,
  });

  final AiKind kind;
  final String prompt;
  final List<String> drafts;

  /// The line SpaceAI says above the phrasings. Often empty — a model that
  /// skips it costs us a sentence, not the answer.
  final String note;
  final int seed;
  final String? url;

  factory AiResult.fromJson(Map<String, dynamic> json) => AiResult(
        kind: AiKind.values.firstWhere((k) => k.name == json['kind'],
            orElse: () => AiKind.draft),
        prompt: json['prompt'] as String? ?? '',
        drafts: List<String>.from(json['drafts'] as List? ?? const []),
        note: json['note'] as String? ?? '',
        seed: (json['seed'] as num?)?.toInt() ?? 0,
        url: json['url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'prompt': prompt,
        'drafts': drafts,
        'note': note,
        'seed': seed,
        'url': url,
      };
}
