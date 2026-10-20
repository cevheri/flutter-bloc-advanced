import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Guards that the widgets in `lib/` show text from the ARB files through `S`, so it follows the app language.
///
/// A string literal handed to a text widget shows the same English to every user: in Turkish the app still showed
/// the login heading, the settings subtitles and the top bar menu in English. This meta-test reads the files in `lib/`
/// that build widgets and fails on a string literal with a letter in it where text is shown: the first argument of
/// `Text` or `SelectableText`; a named argument such as `label:`, `title:`, `tooltip:` or `hintText:`, or the default
/// value of such a parameter; the right side of `??`; a branch of a conditional; and a `return`.
///
/// It guards these common shapes and is not a proof: a literal handed to a helper by position, such as
/// `_statItem('5', 'Core Layers')`, an enum argument, or a literal in a file that builds no widget is not read. The
/// widget tests that show each screen in Turkish cover those. The developer console in `lib/app/dev_console/` opens
/// only in debug builds and is not read.
void main() {
  test('the widgets in lib show text from S, not string literals', () {
    final widgetFiles = <String, String>{};
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || !_roots.any(path.startsWith) || _skippedRoots.any(path.startsWith)) continue;
      final source = file.readAsStringSync();
      if (source.contains('Widget build(BuildContext')) widgetFiles[path] = source;
    }
    final literals = [for (final MapEntry(:key, :value) in widgetFiles.entries) ..._uiTextLiterals(key, value)];

    expect(widgetFiles, isNotEmpty, reason: 'no widget file was found in lib, so the guard no longer reads any');
    expect(
      literals,
      isEmpty,
      reason:
          'These texts do not follow the app language. Add them to lib/l10n/intl_en.arb and intl_tr.arb and show '
          'them with S.of(context):\n${literals.join('\n')}',
    );
  });
}

const _roots = [
  'lib/app/',
  'lib/features/',
  'lib/shared/widgets/',
  'lib/shared/design_system/components/',
  'lib/shared/dynamic_forms/presentation/',
];

const _skippedRoots = ['lib/app/dev_console/'];

/// Literals that read the same in every language.
const _sameInEveryLanguage = {
  "'BLoC Advance'", // the template's short name, which a project renames by hand
  "'ESC'", // the name of a key on the keyboard
  "'en'", // a language code
  "'m@example.com'", // an example address in an input hint
  "'name@example.com'", // an example address in an input hint
  r"'v${AppConstants.appVersion}'", // the version number
  r"'v${AppConstants.appVersion}+${AppConstants.appBuildNumber}'", // the version and build number
};

/// What comes right before a literal that is shown as text, read in code whose comments and string contents are
/// blanked, so that a `?` or a `label:` inside a string is never taken for one.
final _textSite = RegExp(
  r'(?:\b(?:Text|SelectableText)\(\s*'
  r'|\b(?:label|title|subtitle|tooltip|message|hintText|labelText|helperText|errorText|semanticsLabel|description'
  r'|retryLabel|buttonText|createLabel|emptyText|actionLabel)\s*[:=]\s*'
  r'|\?\?\s*|(?<![?.])\?\s+|\breturn\s+)$',
);

final _letter = RegExp('[A-Za-zÇĞİÖŞÜçğıöşü]');
final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_]\w*');

/// The literals in [source] that are shown as text, each as `path:line: literal`.
Iterable<String> _uiTextLiterals(String path, String source) sync* {
  final code = StringBuffer();
  final literals = <({int start, int end})>[];
  for (var i = 0, next = 0; i < source.length; i = next) {
    next = _skip(source, i);
    final token = source.substring(i, next);
    if (token.startsWith('//') || token.startsWith('/*')) {
      code.write(token.replaceAll(RegExp('[^\n]'), ' '));
    } else if (next - i > 1 && _startsLiteral(source, i)) {
      literals.add((start: i, end: next));
      code.write(token.replaceAll(RegExp('[^\n]'), '"'));
    } else {
      code.write(token);
    }
  }
  final blanked = code.toString();
  final shown = <int>{};
  for (var n = 0; n < literals.length; n++) {
    final (:start, :end) = literals[n];
    var isText = _textSite.hasMatch(blanked.substring(max(0, start - 80), start));
    // The other branch of a conditional whose first branch is shown text: `isOnline ? 'Online' : 'Offline'`.
    if (!isText && shown.contains(n - 1)) {
      isText = RegExp(r'^\s*:\s*$').hasMatch(blanked.substring(literals[n - 1].end, start));
    }
    final literal = source.substring(start, end);
    if (!isText || !_letter.hasMatch(literal.replaceAll(_interpolation, ''))) continue;
    if (_sameInEveryLanguage.contains(literal)) continue;
    shown.add(n);
    yield '$path:${'\n'.allMatches(source.substring(0, start)).length + 1}: $literal';
  }
}

bool _startsLiteral(String source, int i) =>
    source[i] == "'" || source[i] == '"' || (source[i] == 'r' && _isRawPrefix(source, i));

bool _isRawPrefix(String source, int i) =>
    i + 1 < source.length &&
    (source[i + 1] == "'" || source[i + 1] == '"') &&
    (i == 0 || !RegExp(r'[\w$]').hasMatch(source[i - 1]));

/// The index after the string literal or the comment that starts at [i], or after the character at [i].
int _skip(String source, int i) {
  if (source.startsWith('//', i)) {
    final end = source.indexOf('\n', i);
    return end == -1 ? source.length : end;
  }
  if (source.startsWith('/*', i)) {
    final end = source.indexOf('*/', i + 2);
    return end == -1 ? source.length : end + 2;
  }
  final raw = source[i] == 'r' && _isRawPrefix(source, i);
  final q = raw ? i + 1 : i;
  if (source[q] != "'" && source[q] != '"') return i + 1;
  final quote = source.startsWith(source[q] * 3, q) ? source[q] * 3 : source[q];
  var j = q + quote.length;
  while (j < source.length && !source.startsWith(quote, j)) {
    if (!raw && source[j] == r'\') {
      j += 2;
    } else if (!raw && source.startsWith(r'${', j)) {
      j = _closingBracket(source, j + 2) + 1;
    } else {
      j++;
    }
  }
  return min(j + quote.length, source.length);
}

/// The index of the bracket that closes the one before [start], skipping strings and comments.
int _closingBracket(String source, int start) {
  var depth = 0;
  for (var i = start; i < source.length; i = _skip(source, i)) {
    if ('([{'.contains(source[i])) depth++;
    if (')]}'.contains(source[i]) && depth-- == 0) return i;
  }
  return source.length;
}
