import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards that a project made from this template does not publish the hosted demo's identity.
///
/// `.github/pages/demo-values.env` holds the hosted demo's values: its URL and path, the template author's repository,
/// docs and sponsor pages, security contact and profile. Only this repository's GitHub Pages job puts them into a build
/// (`--dart-define-from-file` and `scripts/fill_web_placeholders.sh`); `web/` and `lib/` keep `__KEY__` placeholders,
/// which a project fills with its own values. A value written into `web/` or `lib/` instead ships in every copy of the
/// template, so this test fails when a deployment-specific value appears verbatim in a file there (`lib/generated/`
/// excepted), or in `SECURITY.md`, the policy that `web/.well-known/security.txt` sends every copy's reporters to.
///
/// The values that name the template itself (its name, short name and description) are not checked: `web/index.html`
/// and the app still use that name until a project renames it by hand (README, "Customizing for Your Project").
void main() {
  const valuesPath = '.github/pages/demo-values.env';
  const templateNameKeys = {'APP_NAME', 'APP_SHORT_NAME', 'APP_DESCRIPTION'};
  const roots = ['web', 'lib'];
  const files = ['SECURITY.md'];
  const skippedDirectory = 'lib/generated/';

  test('no file a project copies from the template carries a deployment-specific demo value', () {
    final values = {
      for (final MapEntry(:key, :value) in _readValues(valuesPath).entries)
        if (!templateNameKeys.contains(key) && value.isNotEmpty) key: value,
    };
    expect(values, isNotEmpty, reason: '$valuesPath has no deployment-specific values to look for');

    final paths = [
      for (final root in roots)
        for (final entity in Directory(root).listSync(recursive: true))
          if (entity is File && !entity.path.startsWith(skippedDirectory)) entity.path,
      ...files,
    ]..sort();

    final found = [
      for (final path in paths)
        for (final MapEntry(:key, :value) in values.entries)
          if (_contains(File(path).readAsBytesSync(), utf8.encode(value))) '$path: $key ($value)',
    ];

    expect(
      found,
      isEmpty,
      reason:
          'These files carry a value of $valuesPath, so every project made from the template would publish it. '
          'Use the __KEY__ placeholder, or a build-time value, instead:\n${found.join('\n')}',
    );
  });
}

/// Whether [bytes] contains [pattern]. Compares bytes, so binary files under `web/` are searched as they are.
bool _contains(List<int> bytes, List<int> pattern) {
  for (var start = 0; start + pattern.length <= bytes.length; start++) {
    var index = 0;
    while (index < pattern.length && bytes[start + index] == pattern[index]) {
      index++;
    }
    if (index == pattern.length) return true;
  }
  return false;
}

/// The `KEY=value` lines of [path]. Like `scripts/fill_web_placeholders.sh`, this skips empty lines and `#` comments.
Map<String, String> _readValues(String path) => {
  for (final match in RegExp(r'^([A-Z][A-Z0-9_]*)=(.*)$', multiLine: true).allMatches(File(path).readAsStringSync()))
    match[1]!: match[2]!,
};
