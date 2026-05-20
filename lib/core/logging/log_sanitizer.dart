/// Utilities for sanitizing sensitive values before they reach a log sink.
class LogSanitizer {
  /// Returns a redacted preview of a token suitable for logs.
  ///
  /// - `null` or empty → `<empty>`
  /// - shorter than 8 characters → `<redacted>`
  /// - otherwise → `XXXX…YYYY` (first 4 + last 4)
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) return '<empty>';
    if (token.length < 8) return '<redacted>';
    return '${token.substring(0, 4)}…${token.substring(token.length - 4)}';
  }
}
