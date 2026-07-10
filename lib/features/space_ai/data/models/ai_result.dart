/// What SpaceAI can hand back.
enum AiKind { draft, image, video }

/// A generated artefact. For mock media the [seed] drives a deterministic
/// gradient; a real model API will populate [url] instead.
class AiResult {
  const AiResult({
    required this.kind,
    required this.prompt,
    this.drafts = const [],
    this.seed = 0,
    this.url,
  });

  final AiKind kind;
  final String prompt;
  final List<String> drafts;
  final int seed;
  final String? url;

  factory AiResult.fromJson(Map<String, dynamic> json) => AiResult(
        kind: AiKind.values.firstWhere((k) => k.name == json['kind'],
            orElse: () => AiKind.draft),
        prompt: json['prompt'] as String? ?? '',
        drafts: List<String>.from(json['drafts'] as List? ?? const []),
        seed: (json['seed'] as num?)?.toInt() ?? 0,
        url: json['url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'prompt': prompt,
        'drafts': drafts,
        'seed': seed,
        'url': url,
      };
}
