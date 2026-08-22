import 'dart:math' as math;

/// Google hands out profile pictures already scaled down — the URL it stores
/// ends in `=s96-c`, which is a 96×96 thumbnail. That is fine behind a 40pt
/// avatar and hopeless behind a tile 340pt wide on a 3× screen, where it is
/// being stretched past ten times its real size and looks blurred.
///
/// The size is a request parameter, not a property of the stored image, so
/// asking the same URL for a bigger one costs nothing and needs no re-upload.
/// Anything we host ourselves is returned untouched.
///
/// [logicalSize] is the widest edge the image will occupy in logical pixels and
/// [devicePixelRatio] the screen's scale, so a caller can simply pass what it
/// is about to draw.
String sizedAvatarUrl(
  String url, {
  required double logicalSize,
  required double devicePixelRatio,
}) {
  if (url.isEmpty) return url;

  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return url;
  // Exact host or a true subdomain. A bare endsWith would also match
  // "evilgoogleusercontent.com", and the host is compared lowercased because
  // hostnames are case-insensitive while Dart preserves whatever was typed.
  final host = uri.host.toLowerCase();
  if (host != 'googleusercontent.com' &&
      !host.endsWith('.googleusercontent.com')) {
    return url;
  }

  // Round up to a sensible bucket. Google serves any integer, but varying the
  // number per device would defeat both its CDN cache and Flutter's, since the
  // URL is the cache key.
  final wanted = (logicalSize * devicePixelRatio).ceil();
  const buckets = [96, 128, 192, 256, 384, 512, 768, 1024];
  final size = buckets.firstWhere((b) => b >= wanted, orElse: () => 1024);

  // The size directive is the last `=`-separated segment of the path, e.g.
  // ".../ACg8ocIv...=s96-c". Strip whatever is there and ask for our own.
  // `-c` keeps Google's centre crop, which matches the BoxFit.cover we draw
  // with — without it a non-square original comes back letterboxed.
  // Split at the first '?' or '#'. Splitting on '?' alone silently dropped
  // fragments, and the Go side that writes these URLs keeps them.
  var cut = url.length;
  for (final mark in ['?', '#']) {
    final at = url.indexOf(mark);
    if (at >= 0 && at < cut) cut = at;
  }
  final path = url.substring(0, cut);
  final query = url.substring(cut);
  final base = path.contains('=') ? path.substring(0, path.lastIndexOf('=')) : path;
  return '$base=s$size-c$query';
}

/// The widest edge of a rectangle, for callers that draw non-square images.
double longestEdge(double width, double height) => math.max(width, height);
