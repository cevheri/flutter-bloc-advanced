import 'dart:io';

import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dart_code.dart';

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

/// The AppLogger calls in the file at [path], each with the identifiers in its arguments that name a credential.
Iterable<({String location, List<String> credentials})> _logCalls(String path, String source) sync* {
  final code = codeOnly(source);
  for (final match in _callStart.allMatches(code)) {
    // maskToken prints only a masked preview of its argument.
    final arguments = withoutCalls(code.substring(match.end, closingBracket(code, match.end)), 'maskToken');
    yield (
      location: '$path:${'\n'.allMatches(code.substring(0, match.start)).length + 1}',
      credentials: [
        for (final name in _identifier.allMatches(arguments).map((m) => m[0]!).toSet())
          if (sensitiveBodyKeySubstrings.any(name.toLowerCase().contains)) name,
      ],
    );
  }
}
