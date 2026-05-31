import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
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
/// The actual redaction policy (which headers/body keys/JWT shape count
/// as sensitive) lives in `core/security/sensitive_data_scrubber.dart` so
/// this crash-report exit and the debug-log exit share one definition and
/// cannot drift apart.
///
/// Deterministic and free of external side effects, but **mutates the
/// passed-in [SentryEvent] in place** (replacing `event.request` / `event.message`
/// and editing exception values) before returning it — matching the
/// post-deprecation SDK API where `copyWith` is gone. Lives in its own file
/// specifically so tests can exercise it without booting the SDK.

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
      data: scrubBodyKeys(request.data),
      headers: scrubHeaders(request.headers),
      env: request.env,
    );
  }

  final exceptions = event.exceptions;
  if (exceptions != null) {
    for (final ex in exceptions) {
      final v = ex.value;
      if (v != null) ex.value = maskJwts(v);
    }
  }

  final msg = event.message;
  if (msg != null) {
    final formatted = msg.formatted;
    final masked = maskJwts(formatted);
    if (masked != formatted) {
      event.message = SentryMessage(masked);
    }
  }

  return event;
}
