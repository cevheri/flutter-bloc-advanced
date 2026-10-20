import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/dart_code.dart';

/// Guards the laziness of the arguments of the AppLogger calls in `lib/`.
///
/// AppLogger turns an argument into text only when it prints the line, so a level that the filter drops, such as
/// debug in a production build, costs no `toString`. An argument written as `e.toString()`, `jsonEncode(body)` or an
/// interpolated string is built by the caller before AppLogger is called, so its text is built for every call, printed
/// or not. 73 calls in the repositories, the BLoCs and the menu shell passed `x.toString()` this way, on the HTTP and
/// the event paths, and the analytics service built the head of a stack trace before the call.
///
/// This meta-test reads every AppLogger call in `lib/` and fails when an argument that is not a closure calls
/// `toString`, `join` or `jsonEncode`, or holds a string literal with an interpolation. Pass the object itself: AppLogger prints its `toString`, and masks the
/// credential keys of a Map or a List first. For a text that takes work to build, pass a closure that returns it:
/// AppLogger calls it only when it prints the line, so the code inside a closure is not read.
void main() {
  test('no AppLogger call in lib builds the text of an argument before the call', () {
    final calls = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart')) ..._logCalls(file.path, file.readAsStringSync()),
    ];
    final offenders = [
      for (final call in calls)
        for (final argument in call.eagerArguments) '${call.location}: $argument',
    ];

    expect(calls, isNotEmpty, reason: 'no AppLogger call was found in lib, so the guard no longer reads any');
    expect(
      offenders,
      isEmpty,
      reason:
          'These log calls build the text of an argument before AppLogger knows whether it prints the line. Pass the '
          'object itself, or a closure that builds the text:\n${offenders.join('\n')}',
    );
  });
}

/// An AppLogger call on `_log`, on `log`, or on the logger that `AppLogger.getLogger` returns, up to its `(`.
final _callStart = RegExp(r'(?:\b_?log|AppLogger\.getLogger\([^)]*\))\s*\.(?:trace|debug|info|warn|error)\(');

/// A call that builds text: `toString()`, `join(...)` or `jsonEncode(...)`.
final _eagerCall = RegExp(r'\.\s*(?:toString|join)\s*\(|\bjsonEncode\s*\(');

/// A closure: its parameters, then `=>` or the `{` of a block body.
final _closure = RegExp(r'^\(\s*[^)]*\)\s*(?:=>|\{)');

/// The AppLogger calls in the file at [path], each with the arguments that build their text before the call.
Iterable<({String location, List<String> eagerArguments})> _logCalls(String path, String source) sync* {
  final code = codeOnly(source);
  for (final match in _callStart.allMatches(code)) {
    final end = closingBracket(code, match.end);
    final parameters = _items(source, code, match.end, end);
    if (parameters.length < 2) continue;
    final listStart = parameters[1].start;
    if (code[listStart] != '[') continue;
    yield (
      location: '$path:${'\n'.allMatches(code.substring(0, match.start)).length + 1}',
      eagerArguments: [
        for (final (:start, :end) in _items(source, code, listStart + 1, closingBracket(code, listStart + 1)))
          if (_isEager(source.substring(start, end), code.substring(start, end)))
            source.substring(start, end).replaceAll(RegExp(r'\s+'), ' '),
      ],
    );
  }
}

/// Whether the argument whose source is [source] and whose [codeOnly] text is [code] builds its text: it is not a
/// closure, and it calls `toString`, `join` or `jsonEncode`, or holds a string literal with an interpolation.
bool _isEager(String source, String code) =>
    !_closure.hasMatch(code) && (_eagerCall.hasMatch(code) || _interpolates(source, code));

/// Whether [source], whose [codeOnly] text is [code], holds an interpolation: a `$` that [codeOnly] replaced by a space
/// and whose name or expression it kept as code. The `$` of a raw string, of an escape or of a comment leaves only
/// spaces after it.
bool _interpolates(String source, String code) {
  for (var i = 0; i < source.length - 1; i++) {
    if (source[i] != r'$' || code[i] != ' ') continue;
    var j = i + 1;
    if (source[j] == '{') {
      j++;
      while (j < source.length && source[j].trim().isEmpty) {
        j++;
      }
    }
    if (j < source.length && code[j] != ' ' && code[j] == source[j]) return true;
  }
  return false;
}

/// The ranges of the items between [start] and [end] of [code], the [codeOnly] text of [source], split at the commas
/// outside brackets, each trimmed of the spaces of [source], without the empty item that a trailing comma leaves.
List<({int start, int end})> _items(String source, String code, int start, int end) {
  final items = <({int start, int end})>[];
  var depth = 0;
  var itemStart = start;
  void add(int itemEnd) {
    var s = itemStart;
    var e = itemEnd;
    while (s < e && source[s].trim().isEmpty) {
      s++;
    }
    while (e > s && source[e - 1].trim().isEmpty) {
      e--;
    }
    if (s < e) items.add((start: s, end: e));
  }

  for (var i = start; i < end; i++) {
    if ('([{'.contains(code[i])) depth++;
    if (')]}'.contains(code[i])) depth--;
    if (code[i] == ',' && depth == 0) {
      add(i);
      itemStart = i + 1;
    }
  }
  add(end);
  return items;
}
