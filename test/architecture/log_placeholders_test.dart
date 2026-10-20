import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Guards the placeholders of the AppLogger calls in `lib/`.
///
/// AppLogger puts each argument of a call into the next `{}` of its message. An argument with no `{}` left is never
/// printed, and a `{}` with no argument left is printed as it is. So a call whose message has fewer or more `{}` than
/// the call has arguments logs a line that leaves out a value or shows a bare `{}`, and neither fails at runtime or in
/// `flutter analyze`. The two trace lines of `SecurityUtils.isAllowedPath` passed the path and the result without a
/// `{}`, so neither value was ever printed.
///
/// This meta-test reads every AppLogger call in `lib/` whose message is a string literal and whose arguments are a
/// list literal, and fails when the number of `{}` in the message differs from the number of arguments.
void main() {
  test('every AppLogger call in lib has one {} for each argument', () {
    final calls = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart')) ..._logCalls(file.path, file.readAsStringSync()),
    ];
    final mismatches = [
      for (final call in calls)
        if (call.placeholders != call.arguments)
          '${call.location}: ${call.placeholders} {} for ${call.arguments} arguments',
    ];

    expect(calls, isNotEmpty, reason: 'no AppLogger call was found in lib, so the guard no longer reads any');
    expect(
      mismatches,
      isEmpty,
      reason:
          'The message of these log calls has a different number of {} than the call has arguments, so the line '
          'leaves out a value or shows a bare {}:\n${mismatches.join('\n')}',
    );
  });
}

/// An AppLogger call on `_log`, on `log`, or on the logger that `AppLogger.getLogger` returns, up to its `(`.
final _callStart = RegExp(r'(?:\b_?log|AppLogger\.getLogger\([^)]*\))\s*\.(?:trace|debug|info|warn|error)\(');

/// The calls in the file at [path] whose message is a string literal and whose arguments, if any, are a list literal.
Iterable<({String location, int placeholders, int arguments})> _logCalls(String path, String source) sync* {
  final code = _withoutComments(source);
  for (final match in _callStart.allMatches(code)) {
    final parameters = _split(code.substring(match.end, _closingBracket(code, match.end)));
    final message = parameters.isEmpty ? null : _literalText(parameters.first);
    final arguments = switch (parameters.length) {
      1 => const <String>[],
      2 => _listItems(parameters[1]),
      _ => null,
    };
    if (message == null || arguments == null) continue;
    yield (
      location: '$path:${'\n'.allMatches(code.substring(0, match.start)).length + 1}',
      placeholders: '{}'.allMatches(message).length,
      arguments: arguments.length,
    );
  }
}

/// [source] with every comment replaced by spaces and its line breaks kept, so a call quoted in a comment is not read.
String _withoutComments(String source) {
  final code = StringBuffer();
  for (var i = 0, next = 0; i < source.length; i = next) {
    next = _skip(source, i);
    final token = source.substring(i, next);
    code.write(token.startsWith('//') || token.startsWith('/*') ? token.replaceAll(RegExp('[^\n]'), ' ') : token);
  }
  return code.toString();
}

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
  if (source[i] != "'" && source[i] != '"') return i + 1;
  final raw = i > 0 && source[i - 1] == 'r';
  final quote = source.startsWith(source[i] * 3, i) ? source[i] * 3 : source[i];
  var j = i + quote.length;
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

/// [text] split at the commas outside brackets and strings, each item trimmed, without the empty item that a trailing
/// comma leaves.
List<String> _split(String text) {
  final items = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < text.length; i = _skip(text, i)) {
    if ('([{'.contains(text[i])) depth++;
    if (')]}'.contains(text[i])) depth--;
    if (text[i] == ',' && depth == 0) {
      items.add(text.substring(start, i).trim());
      start = i + 1;
    }
  }
  return [...items, text.substring(start).trim()].where((item) => item.isNotEmpty).toList();
}

/// The source of [item] when it is one string literal or several adjacent ones, otherwise null.
String? _literalText(String item) {
  final text = StringBuffer();
  for (var i = 0; i < item.length;) {
    final quote = item[i] == 'r' && i + 1 < item.length ? i + 1 : i;
    if (item[quote] == "'" || item[quote] == '"') {
      final end = _skip(item, quote);
      text.write(item.substring(quote, end));
      i = end;
    } else if (item[i].trim().isEmpty) {
      i++;
    } else {
      return null;
    }
  }
  return text.toString();
}

/// The items of [item] when it is a list literal, otherwise null.
List<String>? _listItems(String item) => item.startsWith('[') && _closingBracket(item, 1) == item.length - 1
    ? _split(item.substring(1, item.length - 1))
    : null;
