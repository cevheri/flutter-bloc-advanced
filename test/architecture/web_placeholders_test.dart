import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the values the GitHub Pages job fills into the hosted demo.
///
/// `web/` keeps `__KEY__` placeholders for template users, and `flutter build web` copies them into `build/web`
/// unchanged. Before the upload, `.github/workflows/build-web.yml` replaces each one in `index.html`, `manifest.json`,
/// `sitemap.xml`, `humans.txt`, `404.html`, `robots.txt` and `.well-known/security.txt` with the value of its
/// `KEY=value` line in `.github/pages/demo-values.env` (`scripts/fill_web_placeholders.sh`) and then fails on any
/// placeholder left (`scripts/check_web_placeholders.sh`).
/// Published unfilled, the placeholders named the app in Chrome's install prompt and sent the canonical link and
/// `og:image` to pages that return 404.
///
/// `lib/infrastructure/config/template_config.dart` reads the links the app shows with `String.fromEnvironment`, with a
/// placeholder as the default. The Pages job builds the app with `--dart-define-from-file` pointing at the same values
/// file, so a key without a value there leaves its placeholder in `main.dart.js`, where the check fails on it too.
///
/// Those steps run only after a push to main, so this meta-test fails earlier, in the pull request that adds a
/// placeholder without a demo value. Like the guard, it skips `__KEYWORD__`, which instruction comments use for every
/// placeholder, and `__PROD_API_URL__`, which appears only in an `index.html` comment and in the production config
/// that the mock-only demo never selects.
void main() {
  const valuesPath = '.github/pages/demo-values.env';
  const webFiles = [
    'web/index.html',
    'web/manifest.json',
    'web/sitemap.xml',
    'web/humans.txt',
    'web/404.html',
    'web/robots.txt',
    'web/.well-known/security.txt',
  ];
  const templateConfigPath = 'lib/infrastructure/config/template_config.dart';
  const keysLeftUnfilled = {'KEYWORD', 'PROD_API_URL'};

  test('the demo values file has a value for every placeholder the Pages job fills', () {
    final values = _readValues(valuesPath);

    final missing = [
      for (final path in webFiles)
        for (final key in _placeholderKeysIn(path).difference(keysLeftUnfilled))
          if ((values[key] ?? '').isEmpty) '$path: __${key}__',
    ];

    expect(
      missing,
      isEmpty,
      reason:
          '$valuesPath has no value for these placeholders, so the Pages job would fail on them '
          'instead of publishing the demo:\n${missing.join('\n')}',
    );
  });

  test('the demo values file has a value for every placeholder the Pages build compiles into the app', () {
    final values = _readValues(valuesPath);

    final missing = [
      for (final key in _environmentKeysWithPlaceholderIn(templateConfigPath))
        if ((values[key] ?? '').isEmpty) '$templateConfigPath: $key',
    ];

    expect(
      missing,
      isEmpty,
      reason:
          '$valuesPath has no value for these build-time keys, so the demo app would keep their placeholders and the '
          'Pages job would fail on them instead of publishing the demo:\n${missing.join('\n')}',
    );
  });
}

/// The keys of the `__KEY__` placeholders in [path].
Set<String> _placeholderKeysIn(String path) =>
    RegExp('__([A-Z][A-Z0-9_]*)__').allMatches(File(path).readAsStringSync()).map((match) => match[1]!).toSet();

/// The keys [path] reads with `String.fromEnvironment('KEY', defaultValue: '__KEY__')`, that is, with a placeholder
/// as the default.
Set<String> _environmentKeysWithPlaceholderIn(String path) =>
    RegExp(r"String\.fromEnvironment\(\s*'([A-Z][A-Z0-9_]*)',\s*defaultValue:\s*'__[A-Z][A-Z0-9_]*__'")
        .allMatches(File(path).readAsStringSync())
        .map((match) => match[1]!)
        .toSet();

/// The `KEY=value` lines of [path]. Like `scripts/fill_web_placeholders.sh`, this skips empty lines and `#` comments.
Map<String, String> _readValues(String path) => {
  for (final match in RegExp(r'^([A-Z][A-Z0-9_]*)=(.*)$', multiLine: true).allMatches(File(path).readAsStringSync()))
    match[1]!: match[2]!,
};
