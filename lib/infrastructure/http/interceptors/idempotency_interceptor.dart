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
/// **Retry stability.** Once generated, the UUID is stashed on
/// `extra['_idempotency_key']` and reused on every subsequent pass through the
/// chain. This survives both [ResilienceInterceptor] retries and
/// [TokenRefreshInterceptor] post-refresh retries because both paths re-fetch
/// the same [RequestOptions] instance.
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
      final existing = options.extra[keyExtraKey] as String?;
      final key = (existing != null && existing.isNotEmpty) ? existing : _uuid.v4();
      options.extra[keyExtraKey] = key;
      options.headers[headerName] = key;
    }

    handler.next(options);
  }
}
