/// Single source of truth for "what counts as sensitive" when data leaves
/// the app: to a crash report ([sentryBeforeSend]), to the local debug logs
/// ([LoggingInterceptor] verbose mode), or to the console through
/// [AppLogger], which runs every line it prints through [maskEmails]. On
/// web with a Sentry DSN each printed line also becomes a breadcrumb.
///
/// Keeping one copy of the redaction policy is a security invariant, not
/// just DRY: two divergent copies guarantee that one exit eventually
/// leaks a secret the other would have stripped.
///
/// Pure and side-effect free — every function returns a new value and
/// never mutates its input, so it is trivially testable without booting
/// the SDK or a Dio client.
library;

/// Header names dropped entirely (compared lower-cased).
const Set<String> sensitiveHeaderNames = {'authorization', 'cookie', 'set-cookie'};

/// Body keys dropped when any of these appears as a lower-cased substring
/// (so `accessToken`, `refreshToken`, `newPassword` all match).
const Set<String> sensitiveBodyKeySubstrings = {'password', 'otp', 'token', 'refreshtoken'};

/// Replacement emitted in place of a matched JWT.
const String jwtMask = '[REDACTED_JWT]';

/// JWT shape: 3 base64url segments separated by dots, each at least 4
/// chars. Conservative — does not match every theoretical JWT, but
/// matches every JWT this app actually mints.
final RegExp jwtPattern = RegExp(r'eyJ[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}');

/// Replace every JWT-shaped token inside [input] with [jwtMask].
String maskJwts(String input) => input.replaceAll(jwtPattern, jwtMask);

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

/// Return a copy of [headers] with [sensitiveHeaderNames] removed.
/// Generic over value type so both `Map<String, String>` (Sentry) and
/// `Map<String, dynamic>` (Dio request options) work.
Map<K, V> scrubHeaders<K, V>(Map<K, V> headers) {
  return Map<K, V>.fromEntries(
    headers.entries.where((e) => !sensitiveHeaderNames.contains(e.key.toString().toLowerCase())),
  );
}

/// Drop [sensitiveBodyKeySubstrings] keys from a `Map`-shaped body.
///
/// Non-Map bodies (raw String, List, multipart) pass through untouched —
/// they would require shape-specific scrubbing and the risk/reward is
/// poor. Only top-level string keys are inspected; callers that also
/// handle raw string bodies should additionally run [maskJwts] over the
/// serialized form to catch embedded tokens.
Object? scrubBodyKeys(Object? body) {
  if (body is! Map) return body;
  final out = <String, dynamic>{};
  body.forEach((k, v) {
    if (k is! String) {
      out[k.toString()] = v;
      return;
    }
    final lower = k.toLowerCase();
    final isSecret = sensitiveBodyKeySubstrings.any(lower.contains);
    if (!isSecret) out[k] = v;
  });
  return out;
}
