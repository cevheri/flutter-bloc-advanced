import 'package:sentry_flutter/sentry_flutter.dart';

/// PII / token scrubber for Sentry events. Runs as the SDK's
/// `beforeSend` hook (see `bootstrap`) so every event is sanitized
/// before leaving the device.
///
/// **Default-on, conservative.** Forks with looser privacy posture can
/// either disable the hook or relax the rules below. The conservative
/// default exists because the alternative — a single forgotten log
/// statement leaking a JWT to Sentry — is much worse than dropping a
/// few extra fields you wanted to keep.
///
/// Pure function: mutates the [SentryEvent] in place (matching the
/// post-deprecation SDK API where `copyWith` is gone) and returns it.
/// Lives in its own file specifically so tests can exercise it without
/// booting the SDK.

const Set<String> _redactedHeaderNames = {'authorization', 'cookie', 'set-cookie'};

const Set<String> _redactedBodyKeySubstrings = {'password', 'otp', 'token', 'refreshtoken'};

/// JWT shape: 3 base64url segments separated by dots, each at least 4
/// chars. Conservative — does not match every theoretical JWT, but
/// matches every JWT this app actually mints.
final RegExp _jwtPattern = RegExp(r'eyJ[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}\.[A-Za-z0-9_-]{4,}');

const String _jwtMask = '[REDACTED_JWT]';

SentryEvent sentryBeforeSend(SentryEvent event) {
  final request = event.request;
  if (request != null) {
    // SentryRequest.data has no public setter (the SDK exposes only
    // an unmodifiable view). Reconstruct with sanitized values while
    // preserving every other field so we don't drop URL/method/env
    // context that's harmless and useful for triage.
    event.request = SentryRequest(
      url: request.url,
      method: request.method,
      queryString: request.queryString,
      cookies: null, // drop entire Cookie field — covered by header scrub but doubled here
      fragment: request.fragment,
      apiTarget: request.apiTarget,
      data: _scrubBody(request.data),
      headers: _scrubHeaders(request.headers),
      env: request.env,
    );
  }

  final exceptions = event.exceptions;
  if (exceptions != null) {
    for (final ex in exceptions) {
      final v = ex.value;
      if (v != null) ex.value = _maskJwt(v);
    }
  }

  final msg = event.message;
  if (msg != null) {
    final formatted = msg.formatted;
    final masked = _maskJwt(formatted);
    if (masked != formatted) {
      event.message = SentryMessage(masked);
    }
  }

  return event;
}

Map<String, String>? _scrubHeaders(Map<String, String>? headers) {
  if (headers == null) return null;
  final out = <String, String>{};
  headers.forEach((k, v) {
    if (!_redactedHeaderNames.contains(k.toLowerCase())) {
      out[k] = v;
    }
  });
  return out;
}

/// Body shapes we strip: `Map` (the common JSON case after Dio
/// decoding). Non-Map bodies (raw String, List, multipart) pass
/// through untouched — they would require shape-specific scrubbing
/// and the risk/reward is poor.
Object? _scrubBody(Object? body) {
  if (body is! Map) return body;
  final out = <String, dynamic>{};
  body.forEach((k, v) {
    if (k is! String) {
      out[k.toString()] = v;
      return;
    }
    final lower = k.toLowerCase();
    final isSecret = _redactedBodyKeySubstrings.any(lower.contains);
    if (!isSecret) out[k] = v;
  });
  return out;
}

String _maskJwt(String input) {
  return input.replaceAll(_jwtPattern, _jwtMask);
}
