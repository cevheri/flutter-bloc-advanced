import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_bloc_advance/core/security/credential_json.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/public_endpoint.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';

/// Backend contract for the refresh endpoint, isolated as named
/// constants so a typo or rename surfaces at one site instead of
/// scattering across the file. Not exported (private to this library)
/// because they describe how *this* interceptor talks to the backend —
/// not a project-wide HTTP policy.
class _RefreshEndpoint {
  static const path = '/api/token/refresh';
  static const requestKeyRefreshToken = 'refresh_token';
  static const responseKeyIdToken = 'id_token';
  static const responseKeyRefreshToken = 'refresh_token';
}

/// HTTP auth header shape. Same locality reasoning as
/// [_RefreshEndpoint] — these are how this layer writes the header,
/// not a cross-feature contract.
class _AuthHeader {
  static const name = 'Authorization';
  static const bearerPrefix = 'Bearer ';
}

/// Callback signature for notifying the app layer that the session has expired
/// and the user must be logged out.
///
/// By using a callback we avoid importing anything from `app/` in the
/// infrastructure layer.
typedef OnSessionExpired = void Function();

/// Factory for the bare [Dio] instance used to POST the refresh
/// request. A separate Dio is needed so the refresh call bypasses the
/// production interceptor chain (otherwise a 401 on `/api/token/refresh`
/// would re-enter this interceptor recursively). Pluggable so tests
/// can short-circuit the POST without depending on `http_mock_adapter`,
/// and so `ApiClient` can add `MockInterceptor` outside production.
/// A factory that reaches the network must reuse the adapter of
/// `sourceDio`, or the refresh token skips its certificate pinning.
typedef RefreshDioFactory = Dio Function(Dio sourceDio);

/// How a token refresh ended. Every request that waits for the refresh gets the same outcome.
sealed class _RefreshOutcome {
  const _RefreshOutcome();
}

/// The session has a new JWT, [idToken]: the one this refresh stored or, on web, the one another browser tab stored
/// while this refresh was on its way, when that tab refreshed the session or signed in.
final class _Refreshed extends _RefreshOutcome {
  const _Refreshed(this.idToken);

  final String idToken;

  /// Masks the JWT, so a log line that prints the outcome does not print the token.
  @override
  String toString() => '_Refreshed(idToken: ${maskToken(idToken)})';
}

/// The stored session cannot be refreshed: no refresh token is stored, the refresh failed or its answer was malformed,
/// or storing or taking back the rotated tokens failed.
final class _RefreshFailed extends _RefreshOutcome {
  const _RefreshFailed();
}

/// A logout or the end of the session wiped, or is wiping, the session the refresh was asked for, in this tab or, on
/// web, in another browser tab, so the answer of the refresh was dropped.
final class _SessionEnded extends _RefreshOutcome {
  const _SessionEnded();
}

/// The tokens in the answer of a refresh: the new JWT, and the new refresh token when the server rotates it.
typedef _RotatedTokens = ({String idToken, String? refreshToken});

/// Intercepts 401 responses and attempts a silent token refresh.
///
/// A 401 from a public endpoint ([isPublicEndpoint]) other than the refresh
/// endpoint is passed on as it is: it rejects the credentials in the request,
/// not an expired token. A 401 from the refresh endpoint still ends the
/// session.
///
/// The refresh request is coalesced via a shared in-flight [Future].
/// When several requests fail with 401 around the same time the first
/// one starts the refresh; the rest await the same Future and retry
/// with the already-rotated token instead of triggering a refresh
/// storm against the refresh endpoint.
///
/// A 401 for a request sent under a session that a logout or the end of
/// the session has wiped since, or is wiping, is neither sent again nor
/// refreshed, so within one app process, which on web is one browser tab,
/// a request one user sent never goes out again with the token of a user
/// who signed in since. A refresh still on its way when the wipe starts
/// drops the rotated tokens, so a relaunch cannot restore the session the
/// user ended. The requests fail with their 401 ([SessionGeneration]).
///
/// On web every browser tab of the app shares the stored session but
/// counts its own [SessionGeneration], so another tab can sign out or
/// refresh the session while this tab's refresh is on its way. Before it
/// acts on the answer, success or failure, the refresh reads the stored
/// refresh token again: when it is gone, the session ended and the answer
/// is dropped; when it is another one, another tab refreshed the session
/// or signed in, so its tokens stay and the requests are sent again with
/// its JWT, even when the server refused this tab's refresh token because
/// that tab had already used it. Each tab reads its own copy of the
/// browser's storage, which takes another tab's change a moment later, so
/// a sign-out in another tab just before or while this tab stores the
/// rotated tokens can still be undone by them. A sign-out in another tab
/// does not end this tab's generation, so a request this tab sent before
/// that sign-out can still go out again with the JWT of a different user
/// who signed in since: when its 401 comes after that sign-in, and when
/// that sign-in comes while this tab's refresh is on its way.
///
/// Deliberately not a [QueuedInterceptor]: the retry goes back through
/// the client's [Dio], so a failed retry reaches [onError] while the
/// call that sent it is still waiting for it. A queued [onError] would
/// hold that error behind the waiting call, and both would hang along
/// with every later failing request.
///
/// Must be registered after [AuthInterceptor], which records the session
/// generation each request is sent under, in the chain. See
/// `ApiClient._createDio` for the single source of truth on order
/// (any inline ASCII diagram here would drift the next time the
/// chain is edited).
class TokenRefreshInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('TokenRefreshInterceptor');

  final Dio _dio;
  final OnSessionExpired? _onSessionExpired;
  final ISecureStorage _secureStorage;
  final RefreshDioFactory _refreshDioFactory;

  /// Shared in-flight refresh. Non-null while a refresh is in progress;
  /// concurrent 401s await the same Future. Cleared on completion (success
  /// or failure) so the next refresh window can start a fresh attempt.
  Future<_RefreshOutcome>? _inFlightRefresh;

  TokenRefreshInterceptor({
    required Dio dio,
    OnSessionExpired? onSessionExpired,
    ISecureStorage? secureStorage,
    RefreshDioFactory? refreshDioFactory,
    // ignore: prefer_initializing_formals
  }) : _dio = dio,
       // ignore: prefer_initializing_formals
       _onSessionExpired = onSessionExpired,
       _secureStorage = secureStorage ?? FlutterSecureStorageAdapter(),
       _refreshDioFactory = refreshDioFactory ?? defaultRefreshDio;

  /// The default [RefreshDioFactory]: a Dio without interceptors that
  /// shares [source]'s adapter, so the refresh token travels through the
  /// same transport as every other request, certificate pinning included.
  /// Never close the returned Dio: that would close the shared adapter.
  ///
  /// It hands the body over as text, so [decodeCredentialJson] decodes it
  /// whatever its content type. The error dio's own decoder throws for a
  /// malformed body is the parser's, whose message on the web repeats the
  /// characters around the error, tokens included.
  static Dio defaultRefreshDio(Dio source) => Dio(
    BaseOptions(
      baseUrl: source.options.baseUrl,
      connectTimeout: source.options.connectTimeout,
      receiveTimeout: source.options.receiveTimeout,
      responseType: ResponseType.plain,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ),
  )..httpClientAdapter = source.httpClientAdapter;

  /// Typed marker that flags a [RequestOptions] as "already retried
  /// once after a successful refresh." A second 401 on the same
  /// request short-circuits to logout instead of attempting another
  /// refresh — prevents infinite refresh loops when the backend keeps
  /// rejecting freshly-rotated tokens (revoked session, clock skew,
  /// backend bug, etc.).
  ///
  /// Uses [Expando] keyed on the [RequestOptions] instance instead of
  /// the prior stringly-typed `extra['_tokenRefresh_retried']`. The
  /// previous shape was vulnerable to map-key collisions and `== true`
  /// comparison drift (would silently fail for `'true'` or `1`).
  /// The Expando is per-instance, so the marker cannot leak to
  /// unrelated requests.
  static final _retriedAfterRefresh = Expando<bool>('_tokenRefresh_retried');

  /// Test-only helpers around the private retry marker. Production
  /// code never calls these — the marker is stamped exclusively by
  /// [_retryWithToken] after a successful refresh round, and read
  /// exclusively by [onError]'s loop-prevention check. Exposed via
  /// `@visibleForTesting` so tests can drive the loop-prevention
  /// branch directly and assert that the retry path stamps the
  /// marker, without leaking the [Expando] mechanism into production
  /// callers.
  @visibleForTesting
  static void debugMarkAsRetried(RequestOptions options) {
    _retriedAfterRefresh[options] = true;
  }

  @visibleForTesting
  static bool debugIsMarkedAsRetried(RequestOptions options) {
    return _retriedAfterRefresh[options] == true;
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 Unauthorized responses
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Avoid refreshing on the refresh endpoint itself to prevent infinite loops
    final requestPath = err.requestOptions.path;
    if (requestPath.contains(_RefreshEndpoint.path)) {
      _log.warn('Refresh endpoint returned 401 — session expired');
      _triggerLogout();
      handler.next(err);
      return;
    }

    // A public endpoint is sent without a token, so its 401 is not about the
    // session: no refresh, and no session to end. For sign-in, OTP,
    // registration and password reset it rejects the credentials or input
    // in the request, and a refresh here would spend the stored refresh
    // token on a wrong password and resend the credentials with a fresh
    // bearer token. The app config is public too: the lifecycle checks read
    // it before sign-in.
    if (isPublicEndpoint(err.requestOptions)) {
      _log.debug('401 from public endpoint {}: no token refresh', [requestPath]);
      handler.next(err);
      return;
    }

    // The session generation the request was sent under, which AuthInterceptor records before it reads the token.
    final sentUnder = AuthInterceptor.sessionGenerationOf(err.requestOptions);
    if (sentUnder == null) {
      // Every request of the client goes through AuthInterceptor first, so this one cannot show which session it was
      // sent under. It is not sent again, spends no refresh token and ends no session.
      _log.error('401 for {} without a session generation: AuthInterceptor must run before this interceptor', [
        requestPath,
      ]);
      handler.next(err);
      return;
    }
    // Checked before anything below acts on the 401, and again once the stored token has been read.
    if (_sessionEnded(sentUnder, requestPath)) {
      handler.next(err);
      return;
    }

    // Second 401 on the same request after a refresh+retry round
    // already happened — refusing to refresh again. The newly-rotated
    // token is being rejected; another refresh would just produce
    // another rejected token. Surface the failure and log out.
    if (_retriedAfterRefresh[err.requestOptions] == true) {
      _log.warn('401 again after refresh+retry for {} — giving up to avoid loop', [requestPath]);
      _triggerLogout();
      handler.next(err);
      return;
    }

    _log.debug('401 received for {} — checking refresh state', [requestPath]);

    // Stale-header short-circuit: if the JWT has already been rotated
    // since this request was sent (e.g. a previous refresh completed
    // while this request was in flight), just retry with the current
    // token. Avoids a second refresh call for a 401 that arrives after
    // the first refresh has completed.
    //
    // ISecureStorage.read can throw on platform / decryption failure
    // (contract from the secure-storage refactor). Treat that as
    // "optimization unavailable" and fall through to the normal
    // refresh path — letting the read escape would break the request
    // pipeline.
    String? currentToken;
    try {
      currentToken = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
    } catch (e) {
      _log.warn('Stale-header check skipped — secure read failed: {}', [e]);
    }
    // A logout or the end of the session can start while the token is read.
    if (_sessionEnded(sentUnder, requestPath)) {
      handler.next(err);
      return;
    }
    // Dio headers are Map<String, dynamic>; defensive narrowing to
    // avoid a runtime crash if a non-String value ever lands on
    // [_AuthHeader.name] (interceptor would otherwise break the entire
    // request pipeline for one malformed header).
    final rawAuth = err.requestOptions.headers[_AuthHeader.name];
    final requestAuth = rawAuth is String ? rawAuth : null;
    final requestToken = (requestAuth != null && requestAuth.startsWith(_AuthHeader.bearerPrefix))
        ? requestAuth.substring(_AuthHeader.bearerPrefix.length)
        : null;
    if (currentToken != null && currentToken.isNotEmpty && requestToken != null && requestToken != currentToken) {
      _log.debug('JWT already rotated since {} was sent — retrying with current token', [requestPath]);
      await _retryWithToken(err, currentToken, handler);
      return;
    }

    switch (await _refreshOnce(sentUnder)) {
      case _Refreshed(:final idToken):
        await _retryWithToken(err, idToken, handler);
      case _RefreshFailed():
        _triggerLogout();
        handler.next(err);
      case _SessionEnded():
        // The session is already over, so there is no token to send the request again with. It is not ended again:
        // the user may have signed in since, and that session must stay.
        handler.next(err);
    }
  }

  /// Whether a logout or the end of the session wiped, or is wiping, the session that the request to [path] was sent
  /// under, [sentUnder]. A token stored now is then of a session signed in to since, maybe by another user, so the
  /// request is not sent again with it, there is no session to refresh, and the session is not ended again: the 401
  /// is passed on.
  bool _sessionEnded(int sentUnder, String path) {
    if (!SessionGeneration.hasEnded(sentUnder)) return false;
    _log.warn('Session of {} ended since it was sent: no retry and no token refresh', [path]);
    return true;
  }

  /// Retry the original request with [token]. Forwards retry failures
  /// (not the original 401) to the handler so the real cause surfaces.
  ///
  /// Marks the request with [_retriedAfterRefresh] so a second 401 on
  /// the retry short-circuits to logout when it reaches [onError] (see
  /// the loop-prevention check there).
  Future<void> _retryWithToken(DioException err, String token, ErrorInterceptorHandler handler) async {
    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers[_AuthHeader.name] = '${_AuthHeader.bearerPrefix}$token';
      _retriedAfterRefresh[retryOptions] = true;
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      _log.error('Retry after refresh failed (type: {}, message: {}, error: {})', [
        retryErr.type.name,
        retryErr.message,
        retryErr.error,
      ]);
      // The retry's error has already been through every error
      // interceptor of the client's Dio. Reject so the rest of this
      // chain skips it; passing it on would handle it twice (e.g.
      // ResilienceInterceptor would count two failures for one retry).
      handler.reject(retryErr);
    } catch (e, st) {
      _log.error('Retry after refresh failed (non-Dio): {}', [e]);
      handler.next(
        DioException(requestOptions: err.requestOptions, error: e, stackTrace: st, type: DioExceptionType.unknown),
      );
    }
  }

  /// Returns a single in-flight refresh Future. The first caller starts
  /// the refresh; concurrent callers await the same Future. Cleared on
  /// completion so subsequent refresh windows start fresh.
  Future<_RefreshOutcome> _refreshOnce(int generation) {
    return _inFlightRefresh ??= _performRefresh(generation).whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  /// Performs the actual refresh call + persistence. Returns [_Refreshed]
  /// with the new idToken on success, or with the JWT of another browser
  /// tab that refreshed the session meanwhile, [_SessionEnded] when the
  /// session of [generation] has ended before the rotated tokens are
  /// stored or while they are, and [_RefreshFailed] on any failure
  /// (missing refresh token, non-2xx response, malformed body, transport
  /// error) of the session that is still stored. [generation] is the
  /// session generation of the request that asked for the refresh.
  Future<_RefreshOutcome> _performRefresh(int generation) async {
    try {
      final refreshToken = await _secureStorage.read(SecureStorageKeys.refreshToken.key);
      if (refreshToken == null || refreshToken.isEmpty) {
        _log.warn('No refresh token available — session expired');
        return const _RefreshFailed();
      }

      final rotated = await _requestRotation(refreshToken);
      // The answer, tokens or a failure, is acted on only while the session the refresh was sent for is stored.
      final movedOn = await _sessionMovedOn(sentRefreshToken: refreshToken, generation: generation);
      if (movedOn != null) return movedOn;
      if (rotated == null) return const _RefreshFailed();
      final (idToken: newIdToken, refreshToken: newRefreshToken) = rotated;

      // Persist the rotated tokens. AuthInterceptor reads JWT from
      // secure storage on every request, so the next outgoing call
      // picks up the rotated value automatically.
      //
      // Both writes are wrapped together with rollback-to-prior so a
      // partial failure (id_token persisted, refresh_token throws)
      // cannot leave a torn pair on disk. A torn pair would let the
      // next request succeed briefly with the new id_token, then fail
      // on the following 401 because the refresh_token is stale — a
      // user-visible logout for a reason unrelated to the original
      // failure. Snapshotting prior values mirrors the pattern in
      // AuthSessionRepositoryImpl.persist.
      String? priorIdToken;
      try {
        priorIdToken = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
      } catch (e) {
        // Snapshot read failed; rollback for jwtToken will fall
        // through to delete. The session-expired callback will then
        // force a clean re-auth.
        _log.warn('Failed to snapshot prior id_token before persist: {}', [e]);
      }

      final hasNewRefreshToken = newRefreshToken != null && newRefreshToken.isNotEmpty;
      try {
        await _secureStorage.write(SecureStorageKeys.jwtToken.key, newIdToken);
        if (hasNewRefreshToken) {
          await _secureStorage.write(SecureStorageKeys.refreshToken.key, newRefreshToken);
        }
      } catch (e, st) {
        _log.error('Persist of rotated tokens failed — rolling back to prior values: {} {}', [e, st]);
        await _restoreOrDelete(SecureStorageKeys.jwtToken, priorIdToken);
        await _restoreOrDelete(SecureStorageKeys.refreshToken, refreshToken);
        return const _RefreshFailed();
      }

      // The session ended while the rotated tokens were being stored, so the wipe may have run before a write landed.
      // Take back what this refresh stored; a session stored since then holds other tokens and stays. A storage failure
      // here reaches the catch below as a failed refresh, which ends the session and so wipes what is stored.
      if (SessionGeneration.hasEnded(generation)) {
        _log.warn('Session ended while the rotated tokens were stored: taking them back');
        await _deleteIfStored(SecureStorageKeys.jwtToken, newIdToken);
        if (hasNewRefreshToken) await _deleteIfStored(SecureStorageKeys.refreshToken, newRefreshToken);
        return const _SessionEnded();
      }

      _log.info('Token refresh successful');
      return _Refreshed(newIdToken);
    } catch (e) {
      _log.error('Unexpected error during token refresh: {}', [e]);
      return const _RefreshFailed();
    }
  }

  /// Sends [refreshToken] to the refresh endpoint and returns the tokens of its answer, or null when the refresh failed
  /// or its answer is malformed. The reason is logged here.
  Future<_RotatedTokens?> _requestRotation(String refreshToken) async {
    try {
      // Use a fresh Dio instance to bypass the interceptor chain.
      final refreshDio = _refreshDioFactory(_dio);

      final response = await refreshDio.post(
        _RefreshEndpoint.path,
        data: jsonEncode({_RefreshEndpoint.requestKeyRefreshToken: refreshToken}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        _log.warn('Token refresh failed with status {}', [response.statusCode]);
        return null;
      }

      // Decode the body, then defensively narrow to Map<String, dynamic>
      // before indexing. A misconfigured backend / proxy could return a
      // JSON array, a bare string, or wrap the payload (e.g. `{"data":
      // {...}}`); in any of those shapes `decoded[id_token]` would throw
      // a NoSuchMethodError that the catch below would swallow as
      // "Unexpected error during token refresh". Surfacing the body
      // shape explicitly makes the misconfiguration debuggable from logs.
      final decoded = response.data is String ? decodeCredentialJson(response.data as String) : response.data;
      if (decoded is! Map<String, dynamic>) {
        _log.error('Refresh response body is not a JSON object (was {})', [decoded.runtimeType]);
        return null;
      }
      final newIdToken = decoded[_RefreshEndpoint.responseKeyIdToken] as String?;
      final newRefreshToken = decoded[_RefreshEndpoint.responseKeyRefreshToken] as String?;

      if (newIdToken == null || newIdToken.isEmpty) {
        _log.error('Refresh response missing id_token');
        return null;
      }
      return (idToken: newIdToken, refreshToken: newRefreshToken);
    } on DioException catch (e) {
      // A failure that dio only wraps, such as a certificate pin mismatch, has no message: its cause is the wrapped
      // error. The refresh request skips the client's interceptors, so nothing else logs it.
      _log.error('Token refresh request failed (type: {}, message: {}, error: {})', [e.type.name, e.message, e.error]);
      return null;
    } catch (e) {
      _log.error('Unexpected error during token refresh: {}', [e]);
      return null;
    }
  }

  /// The outcome for a refresh whose session ended or moved on while the refresh was on its way, or null while the
  /// session it sent [sentRefreshToken] for, under [generation], is still the stored one.
  ///
  /// The session can end or move on in this tab or, on web, in another browser tab, which shares the stored session
  /// but counts its own [SessionGeneration]. The checks run in this order: this tab's generation, the stored refresh
  /// token, then the stored JWT. They hold for a failed refresh too, which must not end a session it was not sent for.
  Future<_RefreshOutcome?> _sessionMovedOn({required String sentRefreshToken, required int generation}) async {
    // A logout or the end of the session in this tab wiped, or is wiping, the stored session. Storing the rotated
    // tokens now would bring back the session the user ended, and a relaunch would restore it.
    if (SessionGeneration.hasEnded(generation)) {
      _log.warn('Session ended during the token refresh: its answer is dropped');
      return const _SessionEnded();
    }
    final storedRefreshToken = await _secureStorage.read(SecureStorageKeys.refreshToken.key);
    // Another tab ended the session. What is stored now is not this session, so it is not ended again either.
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      _log.warn('Session ended in another tab during the token refresh: its answer is dropped');
      return const _SessionEnded();
    }
    if (storedRefreshToken == sentRefreshToken) return null;
    // Another tab refreshed the session, or signed in. Its tokens stay: this answer stored over them could pair this
    // JWT with that tab's refresh token, and a server that accepts a refresh token once has refused this refresh. The
    // requests are sent again with the JWT that tab stored. A tab stores its JWT before its refresh token, so this
    // read, after the refresh token's, sees that JWT or a later one.
    final storedIdToken = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
    // A sign-out deletes the JWT before the refresh token, so a missing JWT is another tab's sign-out under way.
    if (storedIdToken == null || storedIdToken.isEmpty) {
      _log.warn('Session ended in another tab during the token refresh: its answer is dropped');
      return const _SessionEnded();
    }
    _log.info('Session refreshed in another tab during the token refresh: using its tokens');
    return _Refreshed(storedIdToken);
  }

  /// Deletes [key] when it still holds [value], which this refresh stored, and leaves any other value alone.
  Future<void> _deleteIfStored(SecureStorageKeys key, String value) async {
    if (await _secureStorage.read(key.key) == value) await _secureStorage.delete(key.key);
  }

  /// Best-effort rollback helper for [_performRefresh]: writes [prior]
  /// back if it was present, otherwise deletes the key. Swallows any
  /// failure so a rollback never escalates beyond a clean
  /// session-expired callback for the user.
  Future<void> _restoreOrDelete(SecureStorageKeys key, String? prior) async {
    try {
      if (prior != null && prior.isNotEmpty) {
        await _secureStorage.write(key.key, prior);
      } else {
        await _secureStorage.delete(key.key);
      }
    } catch (e) {
      _log.warn('Rollback failed for {}: {}', [key.key, e]);
    }
  }

  void _triggerLogout() {
    if (_onSessionExpired != null) {
      _log.info('Triggering session expired callback');
      _onSessionExpired();
    }
  }
}
