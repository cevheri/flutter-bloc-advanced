import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_bloc_advance/core/security/credential_json.dart';

/// The path of the backend's refresh endpoint in `jwt` mode, relative to the API base URL as every other request path
/// is. A 401 from it ends the session in `TokenRefreshInterceptor`, since there is nothing left to refresh with.
const String refreshEndpointPath = '/token/refresh';

/// The body keys of [refreshEndpointPath]'s request and answer, isolated as named constants so a typo or rename
/// surfaces at one site. Private, because they describe how [BackendTokenRotation] talks to the backend, not a
/// project-wide HTTP policy.
class _BackendRefreshContract {
  static const requestKeyRefreshToken = 'refresh_token';
  static const responseKeyIdToken = 'id_token';
  static const responseKeyRefreshToken = 'refresh_token';
}

/// Decides whether a 401 means that the bearer is no longer valid, which is what makes `TokenRefreshInterceptor`
/// refresh the session, and end it when the refresh cannot fix the 401.
typedef SessionExpiredPredicate = bool Function(DioException error);

/// The default [SessionExpiredPredicate]: every 401 means the bearer is no longer valid.
bool isUnauthorized(DioException error) => error.response?.statusCode == 401;

/// How a token rotation ended.
sealed class TokenRotationResult {
  const TokenRotationResult();
}

/// The rotation gave a new access token, the new refresh token when the server rotates it, and, in `oidc` mode, the
/// new ID token when one is returned and the new access token's expiry.
final class TokensRotated extends TokenRotationResult {
  const TokensRotated({required this.accessToken, this.refreshToken, this.oidcIdToken, this.accessTokenExpiresAt});

  final String accessToken;
  final String? refreshToken;
  final String? oidcIdToken;
  final DateTime? accessTokenExpiresAt;

  /// Masks every token, so a log line that prints the result does not print a credential.
  @override
  String toString() =>
      'TokensRotated(accessToken: ${maskToken(accessToken)}, refreshToken: ${maskToken(refreshToken)}, '
      'oidcIdToken: ${maskToken(oidcIdToken)}, accessTokenExpiresAt: $accessTokenExpiresAt)';
}

/// The server refused the refresh token, or its answer was unusable: the session ends.
final class RotationRefused extends TokenRotationResult {
  const RotationRefused();
}

/// The server could not be reached: the session is kept, the request fails as a network error, and the next 401
/// tries the rotation again.
final class RotationUnavailable extends TokenRotationResult {
  const RotationUnavailable();
}

/// Trades a refresh token for new tokens. `TokenRefreshInterceptor` calls it once per refresh, and stores what it
/// returns; an implementation stores nothing itself.
abstract interface class TokenRotation {
  Future<TokenRotationResult> rotate(String refreshToken);
}

/// A [TokenRotation] that refuses every refresh and sends nothing, so the 401 ends the session.
///
/// A misconfigured `oidc` build cannot reach the identity provider, and a session that an earlier `oidc` build stored
/// holds the provider's refresh token, which [BackendTokenRotation] would post to the backend.
final class RefusingTokenRotation implements TokenRotation {
  const RefusingTokenRotation();

  static final _log = AppLogger.getLogger('RefusingTokenRotation');

  @override
  Future<TokenRotationResult> rotate(String refreshToken) async {
    _log.warn('The session cannot be refreshed: single sign-on is not configured correctly in this build');
    return const RotationRefused();
  }
}

/// Factory for the bare [Dio] instance used to POST the refresh
/// request. A separate Dio is needed so the refresh call bypasses the
/// production interceptor chain (otherwise a 401 on [refreshEndpointPath]
/// would re-enter `TokenRefreshInterceptor` recursively). Pluggable so tests
/// can short-circuit the POST without depending on `http_mock_adapter`,
/// and so `ApiClient` can add `MockInterceptor` outside production.
/// A factory that reaches the network must reuse the adapter of
/// `sourceDio`, or the refresh token skips its certificate pinning.
typedef RefreshDioFactory = Dio Function(Dio sourceDio);

/// The default [RefreshDioFactory]: a Dio without interceptors that
/// shares [source]'s adapter, so the refresh token travels through the
/// same transport as every other request, certificate pinning included.
/// Never close the returned Dio: that would close the shared adapter.
///
/// It hands the body over as text, so [decodeCredentialJson] decodes it
/// whatever its content type. The error dio's own decoder throws for a
/// malformed body is the parser's, whose message on the web repeats the
/// characters around the error, tokens included.
Dio defaultRefreshDio(Dio source) => Dio(
  BaseOptions(
    baseUrl: source.options.baseUrl,
    connectTimeout: source.options.connectTimeout,
    receiveTimeout: source.options.receiveTimeout,
    responseType: ResponseType.plain,
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  ),
)..httpClientAdapter = source.httpClientAdapter;

/// Today's POST /token/refresh, unchanged: every failure is RotationRefused, as in jwt mode today.
final class BackendTokenRotation implements TokenRotation {
  BackendTokenRotation({required this._dio, this._refreshDioFactory = defaultRefreshDio});

  /// The refresh has logged under the interceptor's name since before it moved here, and its lines keep that name.
  static final _log = AppLogger.getLogger('TokenRefreshInterceptor');

  /// The client's Dio, whose adapter [_refreshDioFactory] reuses.
  final Dio _dio;
  final RefreshDioFactory _refreshDioFactory;

  /// Sends [refreshToken] to the refresh endpoint and returns the tokens of its answer, or [RotationRefused] when the
  /// refresh failed or its answer is malformed. The reason is logged here.
  @override
  Future<TokenRotationResult> rotate(String refreshToken) async {
    try {
      // Use a fresh Dio instance to bypass the interceptor chain.
      final refreshDio = _refreshDioFactory(_dio);

      final response = await refreshDio.post(
        refreshEndpointPath,
        data: jsonEncode({_BackendRefreshContract.requestKeyRefreshToken: refreshToken}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        _log.warn('Token refresh failed with status {}', [response.statusCode]);
        return const RotationRefused();
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
        return const RotationRefused();
      }
      final newIdToken = decoded[_BackendRefreshContract.responseKeyIdToken] as String?;
      final newRefreshToken = decoded[_BackendRefreshContract.responseKeyRefreshToken] as String?;

      if (newIdToken == null || newIdToken.isEmpty) {
        _log.error('Refresh response missing id_token');
        return const RotationRefused();
      }
      return TokensRotated(accessToken: newIdToken, refreshToken: newRefreshToken);
    } on DioException catch (e) {
      // A failure that dio only wraps, such as a certificate pin mismatch, has no message: its cause is the wrapped
      // error. The refresh request skips the client's interceptors, so nothing else logs it.
      _log.error('Token refresh request failed (type: {}, message: {}, error: {})', [e.type.name, e.message, e.error]);
      return const RotationRefused();
    } catch (e) {
      _log.error('Unexpected error during token refresh: {}', [e]);
      return const RotationRefused();
    }
  }
}
