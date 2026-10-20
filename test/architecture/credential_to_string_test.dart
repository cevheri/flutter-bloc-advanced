import 'dart:io';

import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dart_code.dart';

/// Guards the text of the classes in `lib/` that hold a credential.
///
/// A log line, the dev console and a Sentry event print an object through its `toString`. An Equatable prints its
/// props there whenever `stringify` is on, which is the default of every debug build, and `PasswordChangeDTO`,
/// `UserJWT` and the change password events forced it on in release builds too. So the debug observer put the
/// sign-in password, the OTP and both passwords of a change into the BLoC and Time Travel tabs of the dev console.
///
/// This meta-test reads every class in `lib/` with a `String` field whose name contains one of
/// [sensitiveBodyKeySubstrings], such as `password`, `otpCode` or `refreshToken`. It fails when the class does not
/// override `toString`, or when its `toString` prints such a field or the props. A token field may be printed through
/// `maskToken`, which keeps four characters at each end; a password or an OTP may not, since that would print most of
/// it.
void main() {
  test('every class in lib with a credential field leaves it out of toString', () {
    final classes = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart')) ..._credentialClasses(file.path, file.readAsStringSync()),
    ];
    final offenders = [
      for (final type in classes)
        if (type.problem != null) '${type.location} ${type.name}: ${type.problem}',
    ];

    expect(
      classes.map((type) => type.name),
      containsAll(['PasswordChangeDTO', 'LoginFormSubmitted', 'JWTToken']),
      reason: 'the guard no longer finds the credential fields it was written for, so it reads nothing',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'These classes hold a credential, and their toString would print it in a log line, the dev console or a '
          'Sentry event. Override toString and print a mask such as secretMask in its place:\n${offenders.join('\n')}',
    );
  });
}

final _classStart = RegExp(r'\bclass\s+(\w+)[^{;]*\{');

final _stringField = RegExp(r'\bString\??\s+(\w+)\s*[;=,]');

final _toString = RegExp(r'\bString\s+toString\s*\(\s*\)\s*');

/// The classes in the file at [path] that declare a credential field, each with what is wrong with its toString, or
/// null when nothing is.
Iterable<({String location, String name, String? problem})> _credentialClasses(String path, String source) sync* {
  final code = codeOnly(source);
  for (final declaration in _classStart.allMatches(code)) {
    final body = code.substring(declaration.end, closingBracket(code, declaration.end));
    final members = _membersOnly(body);
    final credentials = [
      for (final field in _stringField.allMatches(members))
        if (!_isStatic(members, field.start) && sensitiveBodyKeySubstrings.any(field[1]!.toLowerCase().contains))
          field[1]!,
    ];
    if (credentials.isEmpty) continue;
    yield (
      location: '$path:${'\n'.allMatches(code.substring(0, declaration.start)).length + 1}',
      name: declaration[1]!,
      problem: _problem(body, members, credentials),
    );
  }
}

/// What is wrong with the toString of the class whose body is [body], or null when it leaves [credentials] out.
String? _problem(String body, String members, List<String> credentials) {
  final declaration = _toString.firstMatch(members);
  if (declaration == null) return 'does not override toString';
  final text = _toStringBody(body, declaration.end);
  if (RegExp(r'\bprops\b|\bsuper\s*\.\s*toString\b|\bmapPropsToString\b').hasMatch(text)) {
    return 'its toString prints the props';
  }
  final printed = [
    for (final field in credentials)
      if (RegExp('\\b$field\\b')
          .hasMatch(field.toLowerCase().contains('token') ? withoutCalls(text, 'maskToken') : text))
        field,
  ];
  return printed.isEmpty ? null : 'its toString prints ${printed.join(', ')}';
}

/// The code of the toString that starts at [start] in [body]: its expression after `=>`, or its block.
String _toStringBody(String body, int start) {
  if (body.startsWith('=>', start)) {
    final end = body.indexOf(';', start);
    return body.substring(start, end == -1 ? body.length : end);
  }
  return body.substring(start, closingBracket(body, start + 1));
}

/// [body] with the content of every bracket replaced by spaces, so only its member declarations are left, at the
/// same offsets.
String _membersOnly(String body) {
  final members = StringBuffer();
  var depth = 0;
  for (var i = 0; i < body.length; i++) {
    if (')]}'.contains(body[i])) depth--;
    members.write(depth > 0 && body[i] != '\n' ? ' ' : body[i]);
    if ('([{'.contains(body[i])) depth++;
  }
  return members.toString();
}

/// Whether the declaration that the field at [index] of [members] belongs to is static.
bool _isStatic(String members, int index) {
  final start = members.substring(0, index).lastIndexOf(RegExp(r'[;{}]'));
  return RegExp(r'\bstatic\b').hasMatch(members.substring(start + 1, index));
}
