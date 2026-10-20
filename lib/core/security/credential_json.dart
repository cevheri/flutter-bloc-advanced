import 'dart:convert';

/// Decodes [source], a JSON body that carries a credential, such as the response to a sign-in or to a token refresh.
///
/// A malformed body throws a [FormatException] with the fixed message `Malformed JSON` and the offset of the error,
/// where the platform reports one, but neither the source nor the message of the parser. The one [jsonDecode] throws
/// quotes the body: on the VM through its source, and on the web in its message, which is the browser's text for the
/// error. Either way its text would put the tokens into a log line or an error message.
Object? decodeCredentialJson(String source) {
  try {
    return jsonDecode(source);
  } on FormatException catch (e) {
    throw FormatException('Malformed JSON', null, e.offset);
  }
}
