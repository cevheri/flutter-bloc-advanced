import 'package:flutter/foundation.dart' show visibleForTesting;
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
/// Of the request headers, `Authorization`, `Cookie` and `Set-Cookie` are
/// dropped, a header whose name names a credential (a body key, or one of
/// [sensitiveHeaderNameSubstrings]) keeps its name with its whole value
/// masked, and every other header value and every env value is masked like
/// the text of the event. A tag named like a credential has its whole value
/// masked and every other tag value is masked as text, and the text fields
/// and the data of the user are masked like the rest of the event, so a fork
/// that sets an email as the user id or as a tag does not send it.
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
      headers: _scrubHeaderValues(request.headers),
      env: {for (final MapEntry(:key, :value) in request.env.entries) key: _maskText(value)},
    );
  }

  // On web the SDK names an unnamed event after the page path, which
  // carries the route parameters under the path URL strategy.
  event.transaction = _scrubUrlPart(event.transaction);

  final tags = event.tags;
  if (tags != null) event.tags = _scrubTextMap(tags);

  final user = event.user;
  if (user != null) _scrubUser(user);

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
///
/// The breadcrumbs and events the native SDK records itself never pass
/// through this hook. On Android the host app starts the native SDK and
/// scrubs them with a Kotlin copy of these rules (`NativeSentryScrubber.kt`,
/// see `configureNativeSdkStart`); on iOS and macOS they are not scrubbed
/// yet.
///
/// The key `state` is masked as an OIDC value, except in a navigation
/// breadcrumb whose `state` is one of [sentryNavigationTypes]: there
/// `RouteObserverBreadcrumb` writes the navigator event under it.
Breadcrumb? sentryBeforeBreadcrumb(Breadcrumb? breadcrumb) {
  if (breadcrumb == null) return null;
  final message = breadcrumb.message;
  if (message != null) breadcrumb.message = _maskText(message);
  final data = breadcrumb.data;
  if (data != null) {
    final masked = _maskMap(scrubBodyKeys(data) as Map<String, dynamic>);
    final state = data['state'];
    if (breadcrumb.category == 'navigation' && sentryNavigationTypes.contains(state)) masked['state'] = state;
    breadcrumb.data = masked;
  }
  return breadcrumb;
}

/// The navigator events `SentryNavigatorObserver` records, which
/// `RouteObserverBreadcrumb` writes under the key `state`. Public only so
/// that `test/architecture/sentry_native_scrub_patterns_test.dart` can
/// compare it with the copy of the Android host.
@visibleForTesting
const Set<String> sentryNavigationTypes = {'didPush', 'didPop', 'didReplace'};

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

/// Returns [headers] without the [sensitiveHeaderNames], with the whole value
/// of a header whose name names a credential replaced by [secretMask] (an
/// opaque `X-Auth-Token` has no shape to find), and every other value masked
/// as [_maskText] masks text. The names stay as they were.
Map<String, String> _scrubHeaderValues(Map<String, String> headers) => {
  for (final MapEntry(:key, :value) in _scrubTextMap(scrubHeaders(headers)).entries)
    key: _namesHeaderCredential(key) ? secretMask : value,
};

/// Whether the header name [name] contains one of [sensitiveHeaderNameSubstrings].
bool _namesHeaderCredential(String name) {
  final lower = name.toLowerCase();
  return sensitiveHeaderNameSubstrings.any(lower.contains);
}

/// Returns [map] with the whole value of every credential key replaced by
/// [secretMask] and every other value masked as [_maskText] masks text.
Map<String, String> _scrubTextMap(Map<String, String> map) => {
  for (final MapEntry(:key, :value) in (scrubBodyKeys(map) as Map<String, dynamic>).entries)
    key: _maskText(value as String),
};

/// Masks the text fields of [user] as [_maskText] masks text, and its data as
/// a breadcrumb's data is masked.
void _scrubUser(SentryUser user) {
  user
    ..id = _maskOptional(user.id)
    ..username = _maskOptional(user.username)
    ..email = _maskOptional(user.email)
    ..ipAddress = _maskOptional(user.ipAddress)
    ..name = _maskOptional(user.name);
  final data = user.data;
  if (data != null) user.data = _maskMap(scrubBodyKeys(data) as Map<String, dynamic>);
}

/// Masks emails, JWTs and the other secrets [maskSecrets] finds in [value].
String _maskText(String value) => maskEmails(maskSecrets(value));

/// [_maskText] of [value], or null when it is null.
String? _maskOptional(String? value) => value == null ? null : _maskText(value);

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
