import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Opt-in interceptor that attaches an `Idempotency-Key` header to mutating
/// requests so the backend can deduplicate retries.
///
/// **Default disabled.** Opt in per call by setting `extra['idempotency'] = true`
/// on the [RequestOptions]. The convenience methods on `ApiClient` expose this
/// via the `idempotent: true` parameter.
///
/// **Backend dependency.** The header is meaningless unless the server is
/// configured to deduplicate by it (see IETF draft `idempotency-key-header`,
/// Stripe's worked example). The client side of the contract is in this file;
/// the server side is the template user's responsibility.
///
/// **Retry stability.** The key is stamped onto the [RequestOptions] (both the
/// `Idempotency-Key` header and `extra['_idempotency_key']`) on the initial
/// send. It is preserved across retries because the same [RequestOptions]
/// instance — headers and extra included — is reused: `ResilienceInterceptor`
/// replays it through a new bare [Dio] (bypassing the interceptor chain), and
/// `TokenRefreshInterceptor` re-fetches it after refreshing the token. The
/// cached `extra` value also lets this interceptor recover the key on the rare
/// path where it does run again.
///
/// Only acts on POST / PUT / PATCH — `GET`, `HEAD`, `OPTIONS` are safe;
/// `DELETE` is idempotent by HTTP semantics so it does not need the header.
class IdempotencyInterceptor extends Interceptor {
  /// Extra-map flag the caller sets to opt in. Public so call-site helpers
  /// (and tests) can write it without stringly-typed drift.
  static const String optInExtraKey = 'idempotency';

  /// Extra-map slot where the generated UUID is cached for retry stability.
  /// Leading underscore mirrors the existing `_retryAttempt` / `_basePath`
  /// convention in the codebase for "interceptor-internal" extras.
  static const String keyExtraKey = '_idempotency_key';

  /// HTTP header name. The de-facto standard (Stripe, IETF draft).
  static const String headerName = 'Idempotency-Key';

  static const Set<String> _mutatingMethods = {'POST', 'PUT', 'PATCH'};

  final Uuid _uuid;

  IdempotencyInterceptor({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final optedIn = options.extra[optInExtraKey] == true;
    final isMutating = _mutatingMethods.contains(options.method.toUpperCase());

    if (optedIn && isMutating) {
      // Precedence: a key cached from a prior pass (retry stability) wins, then
      // a caller-supplied header (e.g. a domain-derived correlation ID), and
      // only as a last resort do we mint a fresh UUID. This avoids silently
      // overwriting an explicit Idempotency-Key the caller already set.
      final cached = options.extra[keyExtraKey] as String?;
      final headerValue = options.headers[headerName]?.toString();
      final key = (cached != null && cached.isNotEmpty)
          ? cached
          : (headerValue != null && headerValue.isNotEmpty)
              ? headerValue
              : _uuid.v4();
      options.extra[keyExtraKey] = key;
      options.headers[headerName] = key;
    }

    handler.next(options);
  }
}
