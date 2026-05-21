/// Returns a redacted preview of a token suitable for logs.
///
/// - `null` or empty → `<empty>`
/// - shorter than 8 characters → `<redacted>`
/// - otherwise → `XXXX…YYYY` (first 4 + last 4)
///
/// Top-level function rather than a static method on a namespace
/// class — no state, no related helpers, the previous `LogSanitizer`
/// prefix carried zero information.
String maskToken(String? token) {
  if (token == null || token.isEmpty) return '<empty>';
  if (token.length < 8) return '<redacted>';
  return '${token.substring(0, 4)}…${token.substring(token.length - 4)}';
}
