import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the URLs `web/sitemap.xml` sends crawlers to.
///
/// The app keeps Flutter's default hash URL strategy, so its pages live in the URL fragment (`/#/login`) and a path
/// such as `/login` is not a page of the deployed site: GitHub Pages answers it with 404. The sitemap listed `login`,
/// `register` and `forgot-password` that way. Until the app switches to path URLs (`usePathUrlStrategy`) on a host that
/// serves `index.html` for every path, the sitemap lists only the root, the page `web/index.html` declares canonical.
void main() {
  test('the sitemap lists only the canonical root page', () {
    final canonical = RegExp(r'<link rel="canonical" href="([^"]*)">')
        .firstMatch(File('web/index.html').readAsStringSync())![1];
    final locations = RegExp(r'<loc>\s*([^<]*?)\s*</loc>')
        .allMatches(File('web/sitemap.xml').readAsStringSync())
        .map((match) => match[1])
        .toList();

    expect(
      locations,
      equals([canonical]),
      reason: 'The app routes with the URL fragment (/#/login), so any other path in the sitemap returns 404.',
    );
  });
}
