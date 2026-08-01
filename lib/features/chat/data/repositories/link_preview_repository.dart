import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

/// What a link card shows. Everything but [host] is best-effort — a page with
/// no metadata still previews as its domain rather than as raw text.
class LinkPreview {
  const LinkPreview({
    required this.url,
    required this.host,
    this.title = '',
    this.description = '',
    this.imageUrl = '',
    this.siteName = '',
  });

  final String url;
  final String host;
  final String title;
  final String description;
  final String imageUrl;
  final String siteName;

  /// True when there is more to show than the bare domain we already knew.
  bool get isRich => title.isNotEmpty || imageUrl.isNotEmpty;

  factory LinkPreview.fromJson(Map<String, dynamic> json) => LinkPreview(
        url: json['url'] as String? ?? '',
        host: json['host'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        siteName: json['site_name'] as String? ?? '',
      );
}

/// Reads a link's metadata through the backend. The fetch happens server-side
/// so it is cached once for everyone and the app never talks to a stranger's
/// host directly.
class LinkPreviewRepository {
  LinkPreviewRepository(this._client);

  final ApiClient _client;

  // Same link, same story — and a story is re-read every time it is scrolled
  // past, so without this the endpoint would be hit on every rebuild.
  final Map<String, LinkPreview> _cache = {};

  Future<LinkPreview?> preview(String url) async {
    if (url.isEmpty) return null;
    final hit = _cache[url];
    if (hit != null) return hit;
    try {
      final data = await _client.get(
        '/links/preview',
        query: {'url': url},
        receiveTimeout: const Duration(seconds: 20),
      ) as Map<String, dynamic>;
      return _cache[url] = LinkPreview.fromJson(data);
    } on ApiException {
      // The card falls back to its plain chip; a preview is never worth an
      // error message.
      return null;
    }
  }
}

final linkPreviewRepositoryProvider = Provider<LinkPreviewRepository>(
  (ref) => LinkPreviewRepository(ref.watch(apiClientProvider)),
);

/// One preview per URL, kept alive for the session by the repository cache.
final linkPreviewProvider =
    FutureProvider.family<LinkPreview?, String>((ref, url) {
  return ref.watch(linkPreviewRepositoryProvider).preview(url);
});
