import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the browser back and forward buttons on web.
///
/// go_router follows the browser history through the engine, which listens for `popstate` and calls the `history`
/// methods. `web/index.html` once held a script that swallowed every `popstate`, pushed the current URL again, turned
/// `history.back`, `history.forward` and a negative `history.go` into no-ops and armed a `beforeunload` prompt, so back
/// left the user on the same page and leaving the site asked "Leave site?".
///
/// `flutter test` never loads `web/index.html`, so no widget test can see such a script. This meta-test reads the file
/// and fails when it listens for `popstate` or `beforeunload` or replaces a `history` method.
void main() {
  const indexPath = 'web/index.html';

  test('web/index.html leaves the browser history to Flutter', () {
    final html = File(indexPath).readAsStringSync();

    final patterns = {
      'a popstate listener': RegExp(r'''addEventListener\(\s*['"]popstate['"]|onpopstate\s*='''),
      'a beforeunload listener': RegExp(r'''addEventListener\(\s*['"]beforeunload['"]|onbeforeunload\s*='''),
      'a replaced history method': RegExp(r'history\.(back|forward|go|pushState|replaceState)\s*=(?!=)'),
    };
    final found = [
      for (final MapEntry(key: name, value: pattern) in patterns.entries)
        for (final match in pattern.allMatches(html)) '$name: ${match[0]}',
    ];

    expect(
      found,
      isEmpty,
      reason:
          '$indexPath must not intercept the browser history, or back and forward stop working:\n${found.join('\n')}',
    );
  });
}
