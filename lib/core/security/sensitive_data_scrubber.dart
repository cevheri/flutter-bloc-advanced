/// Single source of truth for "what counts as sensitive" when request or
/// response data leaves the app — to a crash report ([sentryBeforeSend])
/// **or** to the local debug logs ([LoggingInterceptor] verbose mode).
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
