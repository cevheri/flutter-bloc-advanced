package com.cevheri.flutter.flutter_bloc_advance

/**
 * Copies of the scrub policy in lib/core/security/sensitive_data_scrubber.dart and
 * lib/infrastructure/analytics/sentry_scrub.dart, which [NativeSentryScrubber] masks native Sentry events and
 * breadcrumbs with.
 *
 * Each pattern is a raw string, which Kotlin reads without escape processing, so its text is the Dart pattern byte
 * for byte. test/architecture/sentry_native_scrub_patterns_test.dart fails when a pattern, a set or a mask here
 * differs from the Dart one: change both together.
 */
object NativeScrubPatterns {
    const val JWT_PATTERN = """eyJ[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}"""
    const val EMAIL_PATTERN = """[A-Za-z0-9._%+-]{1,64}(?:@|%40)[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}"""
    const val JSON_MEMBER_PATTERN = """"([^"\\]{1,64})"(\s*:\s*)("(?:[^"\\]|\\[^\n\r\u2028\u2029])*"|-?[0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)"""
    const val NAMED_VALUE_PATTERN = """(?<![A-Za-z0-9_.\-])([A-Za-z_][A-Za-z0-9_.\-]{0,63})=([^\[&\s#"',;)}\]][^&\s#"',;)}\]]*)"""
    const val BEARER_PATTERN = """(?<![A-Za-z0-9_])(bearer)\s+[A-Za-z0-9\-._~+/]+=*"""

    // Comma-separated, compared as sets by the guard test.
    const val SENSITIVE_HEADER_NAMES = "authorization,cookie,set-cookie"
    const val SENSITIVE_BODY_KEY_SUBSTRINGS = "password,otp,token,refreshtoken,secret"
    const val SENSITIVE_EXACT_KEYS = "code,code_verifier,state,nonce,session_state,id_token_hint"
    const val NAVIGATION_TYPES = "didPush,didPop,didReplace"

    const val SECRET_MASK = "[REDACTED]"
    const val JWT_MASK = "[REDACTED_JWT]"
    const val EMAIL_MASK = "[REDACTED_EMAIL]"
}
