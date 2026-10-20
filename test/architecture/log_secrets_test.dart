import 'dart:io';

import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the arguments of the AppLogger calls in `lib/`.
///
/// AppLogger prints the text of every argument it puts into a line, and the console of a build keeps that line: the
/// IDE console, logcat, the browser console or the iOS device log. `AccountRepository.changePassword` passed the
/// `PasswordChangeDTO` it was sending, so every debug build of main_local printed both passwords.
///
/// This meta-test reads every AppLogger call in `lib/` and fails when an argument, or an interpolation in the message,
/// names a credential: an identifier that contains one of [sensitiveBodyKeySubstrings], such as `passwordChangeDTO`
/// or `event.otpCode`. A token may still be logged through `maskToken`, which keeps four characters at each end.
void main() {
  test('no AppLogger call in lib logs a value named for a credential', () {
    final calls = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart')) ..._logCalls(file.path, file.readAsStringSync()),
    ];
    final offenders = [
      for (final call in calls)
        if (call.credentials.isNotEmpty) '${call.location}: ${call.credentials.join(', ')}',
    ];

    expect(calls, isNotEmpty, reason: 'no AppLogger call was found in lib, so the guard no longer reads any');
    expect(
      offenders,
      isEmpty,
      reason:
          'These log calls pass a value named for a credential, so the line would print it. Log that the action '
          'happened, or the non-secret fields, instead:\n${offenders.join('\n')}',
    );
  });
}

/// An AppLogger call on `_log`, on `log`, or on the logger that `AppLogger.getLogger` returns, up to its `(`.
final _callStart = RegExp(r'(?:\b_?log|AppLogger\.getLogger\([^)]*\))\s*\.(?:trace|debug|info|warn|error)\(');

final _identifier = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');

final _maskTokenCall = RegExp(r'\bmaskToken\s*\(');

/// The AppLogger calls in the file at [path], each with the identifiers in its arguments that name a credential.
Iterable<({String location, List<String> credentials})> _logCalls(String path, String source) sync* {
  final code = _codeOnly(source);
  for (final match in _callStart.allMatches(code)) {
    final arguments = _withoutMaskToken(code.substring(match.end, _closing(code, match.end)));
    yield (
      location: '$path:${'\n'.allMatches(code.substring(0, match.start)).length + 1}',
      credentials: [
        for (final name in _identifier.allMatches(arguments).map((m) => m[0]!).toSet())
          if (sensitiveBodyKeySubstrings.any(name.toLowerCase().contains)) name,
      ],
    );
  }
}

/// [source] with every comment and the text of every string literal replaced by spaces, and its line breaks kept.
/// The code of an interpolation stays, so `'$password'` and `'${dto.password}'` still read as code.
String _codeOnly(String source) {
  final code = StringBuffer();
  var i = 0;
  while (i < source.length) {
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      i = end == -1 ? source.length : end;
    } else if (source.startsWith('/*', i)) {
      final end = source.indexOf('*/', i + 2);
      final next = end == -1 ? source.length : end + 2;
      code.write(source.substring(i, next).replaceAll(RegExp('[^\n]'), ' '));
      i = next;
    } else if (source[i] == "'" || source[i] == '"') {
      i = _writeString(source, i, code);
    } else {
      code.write(source[i]);
      i++;
    }
  }
  return code.toString();
}

/// Writes into [code] what [_codeOnly] keeps of the string literal that starts at [start], and returns the index
/// after the literal.
int _writeString(String source, int start, StringBuffer code) {
  final raw = start > 0 && source[start - 1] == 'r';
  final quote = source.startsWith(source[start] * 3, start) ? source[start] * 3 : source[start];
  var i = start + quote.length;
  while (i < source.length && !source.startsWith(quote, i)) {
    if (!raw && source[i] == r'\') {
      i += 2;
    } else if (!raw && source.startsWith(r'${', i)) {
      final end = _closing(source, i + 2, strings: true);
      code.write(' ${_codeOnly(source.substring(i + 2, end))} ');
      i = end + 1;
    } else if (!raw && source[i] == r'$') {
      final name = RegExp('[A-Za-z_][A-Za-z0-9_]*').matchAsPrefix(source, i + 1);
      code.write(' ${name?[0] ?? ''} ');
      i = name?.end ?? i + 1;
    } else {
      if (source[i] == '\n') code.write('\n');
      i++;
    }
  }
  code.write(' ');
  return i + quote.length > source.length ? source.length : i + quote.length;
}

/// The index of the bracket that closes the one before [start]. With [strings], [text] is source whose string
/// literals are skipped; otherwise it is the output of [_codeOnly], which has none.
int _closing(String text, int start, {bool strings = false}) {
  var depth = 0;
  var i = start;
  while (i < text.length) {
    if (strings && (text[i] == "'" || text[i] == '"')) {
      i = _writeString(text, i, StringBuffer());
      continue;
    }
    if ('([{'.contains(text[i])) depth++;
    if (')]}'.contains(text[i]) && depth-- == 0) return i;
    i++;
  }
  return text.length;
}

/// [code] without its `maskToken(...)` calls, whose argument is logged only as a masked preview.
String _withoutMaskToken(String code) {
  final call = _maskTokenCall.firstMatch(code);
  if (call == null) return code;
  final end = _closing(code, call.end);
  return code.substring(0, call.start) + _withoutMaskToken(end < code.length ? code.substring(end + 1) : '');
}
