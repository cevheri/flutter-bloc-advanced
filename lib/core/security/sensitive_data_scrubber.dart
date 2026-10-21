/// Single source of truth for "what counts as sensitive" when data leaves
/// the app: to a crash report ([sentryBeforeSend] for the event,
/// [sentryBeforeBreadcrumb] for each breadcrumb), to the local debug logs
/// ([LoggingInterceptor] verbose mode), to the Network tab of the dev
/// console ([DevConsoleInterceptor]), to the text of an HTTP error
/// ([ApiClient], [scrubErrorBody]), or to the console through [AppLogger].
/// AppLogger masks the credential keys of a Map or a List argument with
/// [scrubBodyKeys], and runs every line it prints through [maskSecrets] and
/// [maskEmails].
///
/// Keeping one copy of the redaction policy is a security invariant, not
/// just DRY: two divergent copies guarantee that one exit eventually
/// leaks a secret the other would have stripped.
///
/// Pure and side-effect free — every function returns a new value and
/// never mutates its input, so it is trivially testable without booting
/// the SDK or a Dio client.
library;

import 'dart:convert';

/// Header names whose values no log or view may show (compared
/// lower-cased). [scrubHeaders] drops them, and [maskHeaders] keeps them
/// with a masked value.
const Set<String> sensitiveHeaderNames = {'authorization', 'cookie', 'set-cookie'};

/// Body keys whose values are masked when any of these appears as a
/// lower-cased substring (so `accessToken`, `refreshToken`, `newPassword`
/// and `clientSecret` all match).
const Set<String> sensitiveBodyKeySubstrings = {'password', 'otp', 'token', 'refreshtoken', 'secret'};

/// Keys of the OpenID Connect protocol whose values are masked too: the
/// authorization code, the PKCE verifier, `state`, `nonce`, `session_state`
/// and `id_token_hint`. Compared whole and lower-cased, so `statusCode`,
/// `countryCode`, `errorCode` and `stateName` keep their values.
const Set<String> sensitiveExactKeys = {'code', 'code_verifier', 'state', 'nonce', 'session_state', 'id_token_hint'};

/// Keys under which a validation error repeats a value the request sent:
/// Spring's `rejectedValue`, Pydantic's `input` and express-validator's
/// `value`. Compared whole and lower-cased, and only in an error body.
const Set<String> echoedValueKeys = {'rejectedvalue', 'input', 'value'};

/// Replacement printed in place of a password, an OTP or another secret. A
/// class that holds one prints this in its `toString` instead of the value,
/// as `test/architecture/credential_to_string_test.dart` requires.
const String secretMask = '[REDACTED]';

/// Replacement emitted in place of a matched JWT.
const String jwtMask = '[REDACTED_JWT]';

/// JWT shape: 3 base64url segments separated by dots, each at least 4
/// chars. Conservative — does not match every theoretical JWT, but
/// matches every JWT this app actually mints.
final RegExp jwtPattern = RegExp(r'eyJ[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}');

/// Replace every JWT-shaped token inside [input] with [jwtMask].
String maskJwts(String input) => input.replaceAll(jwtPattern, jwtMask);

/// A JSON member whose value is a string or a number: its name, the colon
/// with the spaces around it, and its value.
final RegExp _jsonMember = RegExp(r'"([^"\\]{1,64})"(\s*:\s*)("(?:[^"\\]|\\.)*"|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)');

/// A `name=value` pair, as in a query string or a form body. A value that
/// starts with `[` is already a mask.
final RegExp _namedValue = RegExp(r'''(?<![\w.\-])([A-Za-z_][\w.\-]{0,63})=([^\[&\s#"',;)}\]][^&\s#"',;)}\]]*)''');

/// The credentials of a Bearer authorization. A mask starts with `[`, so it
/// is not matched again.
final RegExp _bearer = RegExp(r'\b(bearer)\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false);

/// Masks the secrets that [input] holds in a shape that names them: the
/// value of a JSON member or of a `name=value` pair whose name contains one
/// of [sensitiveBodyKeySubstrings] or is one of [sensitiveExactKeys], the
/// credentials of a `Bearer` authorization, and every JWT. A value that is
/// already a mask is kept.
///
/// [AppLogger] runs every line it prints through this, and the Sentry
/// scrubbers every text they send. A secret in free text has no shape to
/// find, so it has to be kept out of the text where it is written.
String maskSecrets(String input) {
  var text = input.contains('eyJ') ? maskJwts(input) : input;
  final lower = text.toLowerCase();
  if (lower.contains('bearer')) text = text.replaceAllMapped(_bearer, (match) => '${match[1]} $secretMask');
  if (!sensitiveBodyKeySubstrings.any(lower.contains) && !sensitiveExactKeys.any(lower.contains)) return text;
  if (text.contains('"')) {
    text = text.replaceAllMapped(_jsonMember, (match) {
      final value = match[3]!;
      if (!_isSensitiveKey(match[1]) || value.startsWith('"[REDACTED')) return match[0]!;
      return '"${match[1]}"${match[2]}${value.startsWith('"') ? '"$secretMask"' : secretMask}';
    });
  }
  if (text.contains('=')) {
    text = text.replaceAllMapped(_namedValue, (m) => _isSensitiveKey(m[1]) ? '${m[1]}=$secretMask' : m[0]!);
  }
  return text;
}

/// Replacement emitted in place of a matched email address.
const String emailMask = '[REDACTED_EMAIL]';

/// Email shape, with the `@` either raw or percent-encoded as `%40`, the
/// way a URL query string carries it. The local part also accepts `%`, so
/// an encoded character such as the `%2B` in `jane%2Btag%40example.com`
/// is masked along with the rest of the address. Practical rather than
/// RFC 5322 complete: it matches the addresses people actually use.
///
/// The local part matches at most 64 characters, the RFC 5321 limit, so a
/// longer one keeps its leading characters. The bound keeps the scan linear:
/// unbounded, a long run of local-part characters without an `@` made it
/// quadratic, and past Dart's backtracking limit the match failed and the
/// address after the run was left unmasked.
final RegExp emailPattern = RegExp(r'[A-Za-z0-9._%+-]{1,64}(?:@|%40)[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}');

/// Replace every email address inside [input] with [emailMask].
///
/// A string without an `@` or a `%40` holds no address, so it is returned
/// without a scan: AppLogger runs every printed line through this.
String maskEmails(String input) {
  if (!input.contains('@') && !input.contains('%40')) return input;
  return input.replaceAll(emailPattern, emailMask);
}

/// Return a copy of [headers] in which the value of every
/// [sensitiveHeaderNames] header is replaced by [secretMask]. Unlike
/// [scrubHeaders] it keeps the header, for a view such as the dev console
/// that shows whether a request carried one.
Map<String, Object?> maskHeaders(Map<String, Object?> headers) => {
  for (final MapEntry(:key, :value) in headers.entries)
    key: sensitiveHeaderNames.contains(key.toLowerCase()) ? secretMask : value,
};

/// Return a copy of [headers] with [sensitiveHeaderNames] removed.
/// Generic over value type so both `Map<String, String>` (Sentry) and
/// `Map<String, dynamic>` (Dio request options) work.
Map<K, V> scrubHeaders<K, V>(Map<K, V> headers) {
  return Map<K, V>.fromEntries(
    headers.entries.where((e) => !sensitiveHeaderNames.contains(e.key.toString().toLowerCase())),
  );
}

/// Return a copy of [body] in which the value of every key that contains
/// one of [sensitiveBodyKeySubstrings], or is one of [sensitiveExactKeys],
/// is replaced by [secretMask], in nested maps and lists too. The key
/// stays, so a reader still sees that the field was there, and a null value
/// stays null.
///
/// A body that is not a Map or a List (raw String, multipart) passes
/// through untouched, since it would require shape-specific scrubbing;
/// callers that also handle raw string bodies should additionally run
/// [maskJwts] over the serialized form to catch embedded tokens.
Object? scrubBodyKeys(Object? body) => _scrubKeys(body, _isSensitiveKey);

/// Returns [body], a request or a response body, as text without its
/// credentials, for a view that shows it, such as the dev console. A JSON
/// string, a Map or a List has its values masked as [scrubBodyKeys] masks
/// them, and every JWT is masked last. A body with nothing to mask keeps
/// its text, the formatting of a JSON string included.
///
/// The values of [sensitiveKeys] are masked too, for a secret whose key
/// names no credential, such as the key a server-driven form gives its
/// password field. They are compared whole and lower-cased.
String scrubBodyText(Object? body, {Set<String> sensitiveKeys = const {}}) =>
    _scrubBodyText(body, _sensitiveKeyTest(sensitiveKeys), const []);

/// Returns [body], the body of an error response, as text without the
/// credentials it may hold. ApiClient puts it into the exception it throws,
/// whose text reaches the log, the dev console and Sentry.
///
/// It is scrubbed as [scrubBodyText] scrubs a body with [sensitiveKeys],
/// and the values under [echoedValueKeys] are masked too. Every value of
/// [requestBody] that such a scrub would mask is masked wherever the body
/// repeats it, so a free-text detail that names the OTP is caught too.
String scrubErrorBody(Object? body, {Object? requestBody, Set<String> sensitiveKeys = const {}}) {
  final isSensitive = _sensitiveKeyTest(sensitiveKeys);
  final secrets = _secretValues(_decoded(requestBody), isSensitive).toSet().toList()
    ..sort((a, b) => b.length - a.length);
  bool isSecret(Object? key) => isSensitive(key) || echoedValueKeys.contains('$key'.toLowerCase());
  return _scrubBodyText(body, isSecret, secrets);
}

String _scrubBodyText(Object? body, bool Function(Object? key) isSecret, List<String> secrets) {
  if (body == null) return '';
  final decoded = _decoded(body);
  final String text;
  if (body is String && (decoded is Map || decoded is List)) {
    final scrubbed = jsonEncode(_maskValues(_scrubKeys(decoded, isSecret), secrets), toEncodable: _text);
    text = scrubbed == jsonEncode(decoded, toEncodable: _text) ? body : scrubbed;
  } else if (body is Map || body is List) {
    text = '${_maskValues(_scrubKeys(body, isSecret), secrets)}';
  } else {
    text = _maskValues('$body', secrets) as String;
  }
  return maskJwts(text);
}

/// A value of the request shorter than this is not looked for in an error
/// body: masking every occurrence of one to three characters would garble
/// it, and [echoedValueKeys] still masks a short value that a validation
/// error repeats.
const int _minEchoedLength = 4;

bool _isSensitiveKey(Object? key) {
  final lower = '$key'.toLowerCase();
  return sensitiveBodyKeySubstrings.any(lower.contains) || sensitiveExactKeys.contains(lower);
}

/// [_isSensitiveKey], which also matches each of [sensitiveKeys], compared
/// whole and lower-cased.
bool Function(Object? key) _sensitiveKeyTest(Set<String> sensitiveKeys) {
  if (sensitiveKeys.isEmpty) return _isSensitiveKey;
  final names = {for (final key in sensitiveKeys) key.toLowerCase()};
  return (key) => _isSensitiveKey(key) || names.contains('$key'.toLowerCase());
}

Object? _scrubKeys(Object? body, bool Function(Object? key) isSecret) => switch (body) {
  Map() => <String, dynamic>{
    for (final MapEntry(:key, :value) in body.entries)
      '$key': isSecret(key) && value != null ? secretMask : _scrubKeys(value, isSecret),
  },
  List() => [for (final item in body) _scrubKeys(item, isSecret)],
  _ => body,
};

/// [body] decoded when it is a JSON string, otherwise [body] itself.
Object? _decoded(Object? body) {
  if (body is! String) return body;
  try {
    return jsonDecode(body);
  } on FormatException {
    return body;
  }
}

/// The values [node] holds under a key that [isSensitive] matches, in
/// nested maps and lists too, as text.
Iterable<String> _secretValues(Object? node, bool Function(Object? key) isSensitive) sync* {
  if (node is Map) {
    for (final MapEntry(:key, :value) in node.entries) {
      yield* isSensitive(key) ? _scalars(value) : _secretValues(value, isSensitive);
    }
  } else if (node is List) {
    for (final item in node) {
      yield* _secretValues(item, isSensitive);
    }
  }
}

/// The text of every string and number in [node] that is at least
/// [_minEchoedLength] characters long.
Iterable<String> _scalars(Object? node) sync* {
  if (node is Map) {
    for (final value in node.values) {
      yield* _scalars(value);
    }
  } else if (node is List) {
    for (final item in node) {
      yield* _scalars(item);
    }
  } else if ((node is String || node is num) && '$node'.length >= _minEchoedLength) {
    yield '$node';
  }
}

/// [node] with every occurrence of each of [secrets] in its strings, and
/// every number equal to one, replaced by [secretMask].
Object? _maskValues(Object? node, List<String> secrets) => switch (node) {
  _ when secrets.isEmpty => node,
  final String text => secrets.fold<String>(text, (masked, secret) => masked.replaceAll(secret, secretMask)),
  num() when secrets.contains('$node') => secretMask,
  Map() => {for (final MapEntry(:key, :value) in node.entries) key: _maskValues(value, secrets)},
  List() => [for (final item in node) _maskValues(item, secrets)],
  _ => node,
};

/// What [jsonEncode] writes for a value it cannot encode: its text.
Object? _text(Object? value) => '$value';
