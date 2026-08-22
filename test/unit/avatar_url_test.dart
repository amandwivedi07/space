import 'package:flutter_test/flutter_test.dart';
import 'package:space_flutter/core/utils/avatar_url.dart';

void main() {
  // The exact URL shape stored for a Google account, taken from production.
  const google =
      'https://lh3.googleusercontent.com/a/ACg8ocIvVRjYBA8oQNEPpQ8V6uDtKTQP_BHjL4cx5wMHmtNK4Fchuw=s96-c';

  String at(String url, double size, double dpr) =>
      sizedAvatarUrl(url, logicalSize: size, devicePixelRatio: dpr);

  group('sizedAvatarUrl', () {
    test('replaces the 96px thumbnail with a size that fits a large tile', () {
      // A featured tile ~340pt wide on a 3x screen wants ~1020px.
      expect(at(google, 340, 3), endsWith('=s1024-c'));
      expect(at(google, 340, 3), startsWith('https://lh3.googleusercontent.com/a/'));
      expect(at(google, 340, 3), isNot(contains('=s96-c')));
    });

    test('asks for less on a small avatar', () {
      expect(at(google, 40, 3), endsWith('=s128-c'));
      expect(at(google, 48, 2), endsWith('=s96-c'));
    });

    test('buckets sizes so the CDN and image cache still hit', () {
      // Sizes inside one bucket must collapse to a single URL, or every device
      // would fetch and cache its own variant. 200/210/250 at 3x are 600/630/
      // 750 physical pixels, all served by the 768 bucket.
      final a = at(google, 200, 3);
      expect(at(google, 210, 3), a);
      expect(at(google, 250, 3), a);
      expect(a, endsWith('=s768-c'));

      // A size in the next bucket down must NOT collapse into it, otherwise
      // the bucketing is just a constant.
      expect(at(google, 170, 3), endsWith('=s512-c'));
    });

    test('keeps the centre crop, which matches BoxFit.cover', () {
      expect(at(google, 340, 3), contains('-c'));
    });

    test('handles a URL that carries no size directive', () {
      const bare = 'https://lh3.googleusercontent.com/a/ACg8ocIvVRjYBA8';
      expect(at(bare, 340, 3), '$bare=s1024-c');
    });

    test('preserves a query string', () {
      const withQuery = '$google?foo=bar';
      final out = at(withQuery, 340, 3);
      expect(out, endsWith('?foo=bar'));
      expect(out, contains('=s1024-c'));
    });

    test('leaves our own media untouched — it is served at full size', () {
      const ours =
          'https://app.spacechatapp.com/media/9f1c2d.jpg?sig=abc&expires=123';
      expect(at(ours, 340, 3), ours);
    });

    test('a look-alike host is not ours', () {
      // A bare endsWith('googleusercontent.com') matched this, and rewrote a
      // URL on a host nobody here controls.
      const evil = 'https://evilgoogleusercontent.com/a/ABC=s96-c';
      expect(at(evil, 340, 3), evil);

      const suffixed = 'https://googleusercontent.com.attacker.net/a/ABC';
      expect(at(suffixed, 340, 3), suffixed);
    });

    test('a real subdomain still matches, whatever its case', () {
      // Hostnames are case-insensitive; Dart preserves what it was given.
      final out = at('https://LH3.GoogleUserContent.com/a/ABC=s96-c', 340, 3);
      expect(out, endsWith('=s1024-c'));
    });

    test('keeps a fragment', () {
      // Splitting on '?' alone dropped these on the floor.
      final out = at('$google#frag', 340, 3);
      expect(out, endsWith('#frag'));
      expect(out, contains('=s1024-c'));
    });

    test('leaves an empty url alone', () {
      expect(at('', 340, 3), '');
    });

    test('never exceeds the largest bucket', () {
      expect(at(google, 4000, 4), endsWith('=s1024-c'));
    });
  });
}
