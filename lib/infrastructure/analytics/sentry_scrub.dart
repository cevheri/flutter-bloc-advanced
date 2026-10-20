import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// PII / token scrubber for Sentry events. Runs as the SDK's
/// `beforeSend` hook (see [installSentryScrubbers]) so every event is
/// sanitized before leaving the device. Its breadcrumbs were already
/// scrubbed by [sentryBeforeBreadcrumb] when each was added.
///
/// **Default-on, conservative.** Forks with looser privacy posture can
/// either disable the hook or relax the rules below. The conservative
/// default exists because the alternative — a single forgotten log
/// statement leaking a JWT to Sentry — is much worse than dropping a
/// few extra fields you wanted to keep.
///
/// The actual redaction policy (which headers/body keys/JWT and email
/// shapes count as sensitive) lives in
/// `core/security/sensitive_data_scrubber.dart` so this crash-report exit
/// and the debug-log exit share one definition and cannot drift apart.
///
/// Deterministic and free of external side effects, but **mutates the
/// passed-in [SentryEvent] in place** (replacing `event.request` and editing
/// the message and the exception values) before returning it, matching the
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
      url: _scrubUrlPart(request.url),
      method: request.method,
      queryString: _scrubUrlPart(request.queryString),
      cookies: null, // drop entire Cookie field — covered by header scrub but doubled here
      fragment: _scrubUrlPart(request.fragment),
      apiTarget: request.apiTarget,
      data: _maskValue(scrubBodyKeys(request.data)),
      headers: scrubHeaders(request.headers),
      env: request.env,
    );
  }

  // On web the SDK names an unnamed event after the page path, which
  // carries the route parameters under the path URL strategy.
  event.transaction = _scrubUrlPart(event.transaction);

  final exceptions = event.exceptions;
  if (exceptions != null) {
    for (final ex in exceptions) {
      final v = ex.value;
      if (v != null) ex.value = _maskText(v);
    }
  }

  final msg = event.message;
  if (msg != null) {
    msg.formatted = _maskText(msg.formatted);
    final template = msg.template;
    if (template != null) msg.template = _maskText(template);
    final params = msg.params;
    if (params != null) msg.params = [for (final param in params) _maskValue(param)];
  }

  return event;
}

/// PII / token scrubber for Sentry breadcrumbs. Runs as the SDK's
/// `beforeBreadcrumb` hook (see [installSentryScrubbers]) on every
/// breadcrumb: those of `SentryAnalyticsService` and the navigation
/// breadcrumbs. It also covers the http and ui breadcrumbs a fork adds
/// through `sentry_dio` or `SentryUserInteractionWidget`, and a printed line
/// if a fork turns print breadcrumbs back on. Masks emails, JWTs and the
/// other secrets [maskSecrets] finds in the message and in every string of
/// the data, at any depth, and the value of every credential key of the
/// data.
///
/// The hook runs when a breadcrumb is added, before the scope keeps it and
/// passes it on to the native SDK, so the copy the native SDK keeps for its
/// own crash reports is scrubbed too. Mutates the passed-in [Breadcrumb] in
/// place and returns it. Never drops one, and never edits the map the
/// caller passed as its data.
Breadcrumb? sentryBeforeBreadcrumb(Breadcrumb? breadcrumb) {
  if (breadcrumb == null) return null;
  final message = breadcrumb.message;
  if (message != null) breadcrumb.message = _maskText(message);
  final data = breadcrumb.data;
  if (data != null) breadcrumb.data = _maskMap(scrubBodyKeys(data) as Map<String, dynamic>);
  return breadcrumb;
}

/// Installs [sentryBeforeSend] as the `beforeSend` hook and
/// [sentryBeforeBreadcrumb] as the `beforeBreadcrumb` hook of [options].
/// `AppBootstrap` calls it when it starts Sentry. Both are needed: an
/// error event takes its breadcrumbs from the scope, and only
/// `beforeBreadcrumb` scrubs them there.
///
/// It also turns print breadcrumbs off. On web the SDK runs the app in a
/// zone that made a breadcrumb of every printed line, so every line
/// `AppLogger` logged, and a scrubber cannot find a password or a code in
/// free text. Native builds never turned `AppLogger` lines into breadcrumbs,
/// so web now matches them. In a release build this also stops recording
/// `debugPrint` lines.
void installSentryScrubbers(SentryOptions options) {
  options.beforeSend = (event, hint) => sentryBeforeSend(event);
  options.beforeBreadcrumb = (breadcrumb, hint) => sentryBeforeBreadcrumb(breadcrumb);
  options.enablePrintBreadcrumbs = false;
}

/// Masks emails and JWTs in a URL or in one of its parts. Route and query
/// parameters travel there: on web the SDK copies the page location into
/// the request, so the email in `/login-otp-verify/:email` would reach
/// Sentry, and a link such as `?token=` or `#access_token=` holds a JWT.
String? _scrubUrlPart(String? value) => value == null ? null : _maskText(value);

/// Masks emails, JWTs and the other secrets [maskSecrets] finds in [value].
String _maskText(String value) => maskEmails(maskSecrets(value));

/// Masks every string in [value] the way Sentry sends it: inside maps and
/// lists at any depth. Any other value that is not a number or a bool is
/// sent as its toString, so it is masked as that text.
Object? _maskValue(Object? value) => switch (value) {
  String() => _maskText(value),
  Map<String, dynamic>() => _maskMap(value),
  Map() => {for (final MapEntry(:key, value: nested) in value.entries) key: _maskValue(nested)},
  List() => [for (final item in value) _maskValue(item)],
  null || num() || bool() => value,
  _ => _maskText(value.toString()),
};

/// Returns a masked copy of [map] that is still a `Map<String, dynamic>`:
/// before handing a breadcrumb to the native SDK, Sentry turns a nested map
/// of any other type into its toString.
Map<String, dynamic> _maskMap(Map<String, dynamic> map) => {
  for (final MapEntry(:key, :value) in map.entries) key: _maskValue(value),
};
