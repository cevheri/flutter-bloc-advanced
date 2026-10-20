import 'package:flutter_bloc_advance/core/security/credential_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeCredentialJson', () {
    test('decodes a JSON body', () {
      expect(decodeCredentialJson('{"id_token":"a","refresh_token":"b"}'), {'id_token': 'a', 'refresh_token': 'b'});
    });

    // The FormatException that jsonDecode throws quotes the body around the error, so its text carried the tokens.
    test('throws a FormatException that keeps the offset of a malformed body but not its text', () {
      expect(
        () => decodeCredentialJson('{"id_token":"at-opaque-0a1b2c3d","refresh_token":"rt-9f8e7d6c"'),
        throwsA(
          isA<FormatException>()
              .having((e) => e.offset, 'offset', 62)
              .having((e) => e.toString(), 'text', allOf(isNot(contains('at-opaque')), isNot(contains('rt-9f8e')))),
        ),
      );
    });

    // On the web the message of that FormatException is the browser's text for the error, which repeats up to ten
    // characters on each side of an unexpected token, or the whole body when it is short. A test on the VM, where the
    // parser's message names no characters, sees that only through an exact message.
    test('throws a FormatException whose message is fixed instead of the text of the parser', () {
      expect(
        () => decodeCredentialJson('{"id_token":at-opaque-0a1b2c3d,"refresh_token":"rt-9f8e7d6c"}'),
        throwsA(
          isA<FormatException>()
              .having((e) => e.message, 'message', 'Malformed JSON')
              .having((e) => e.source, 'source', isNull)
              .having((e) => e.offset, 'offset', 12),
        ),
      );
    });
  });
}
