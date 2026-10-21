import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oidc/oidc.dart';

const fakeIssuer = 'https://idp.test/realms/demo';
const fakeClientId = 'app-client';
const fakeSubject = 'user-1';

/// The signing key of every [FakeProvider], generated once per test file because RSA key generation is slow.
final JsonWebKey _signingKey = _rsaKey('k1');

/// A key the provider does not publish, for an ID token with a bad signature.
final JsonWebKey _foreignKey = _rsaKey('k1');

JsonWebKey _rsaKey(String kid) {
  final generated = JsonWebKey.generate('RS256');
  return JsonWebKey.fromJson({...generated.toJson(), 'kid': kid, 'alg': 'RS256', 'use': 'sig'})!;
}

/// An OpenID provider behind a [MockClient]: discovery, JWKS and the token endpoint, with RS256 ID tokens.
///
/// Every request is recorded in [requests]. The answers follow the knobs below, so a test sets only what it changes.
final class FakeProvider {
  FakeProvider({this.issuer = fakeIssuer, this.endSessionEndpoint = true});

  final String issuer;

  /// Whether discovery advertises an `end_session_endpoint`.
  final bool endSessionEndpoint;

  /// Every request the client sent, in order.
  final requests = <http.Request>[];

  /// The `aud` of the ID tokens the provider signs.
  String audience = fakeClientId;

  /// Signs ID tokens with a key the JWKS does not hold.
  bool signWithForeignKey = false;

  /// The `issuer` discovery names; null names [issuer].
  String? discoveryIssuer;

  /// Overrides the discovery answer; it may throw to simulate an unreachable provider.
  FutureOr<http.Response> Function()? discoveryAnswer;

  /// Overrides the JWKS answer; it may throw.
  FutureOr<http.Response> Function()? jwksAnswer;

  /// Overrides the token endpoint answer to a code exchange; it may throw.
  FutureOr<http.Response> Function()? codeAnswer;

  /// Overrides the token endpoint answer to a refresh; it may throw.
  FutureOr<http.Response> Function()? refreshAnswer;

  /// The `expires_in` of the token answers, or null to leave it out.
  int? expiresIn = 300;

  /// Whether a refresh answer carries a new ID token.
  bool refreshReturnsIdToken = true;

  /// The nonce the last authorization request sent, which the code exchange puts into the ID token.
  String? nonce;

  var _counter = 0;

  late final http.Client client = MockClient(_answer);

  Uri get discoveryUri => OidcUtils.getOpenIdConfigWellKnownUri(Uri.parse(issuer));

  Uri get tokenUri => Uri.parse('$issuer/protocol/openid-connect/token');

  Uri get logoutUri => Uri.parse('$issuer/protocol/openid-connect/logout');

  /// The requests sent to the token endpoint.
  List<http.Request> get tokenRequests => [
    for (final request in requests)
      if (request.url == tokenUri) request,
  ];

  /// The form of a token request.
  static Map<String, String> form(http.Request request) => Uri.splitQueryString(request.body);

  Map<String, dynamic> get discovery => {
    'issuer': discoveryIssuer ?? issuer,
    'authorization_endpoint': '$issuer/protocol/openid-connect/auth',
    'token_endpoint': tokenUri.toString(),
    'jwks_uri': '$issuer/protocol/openid-connect/certs',
    if (endSessionEndpoint) 'end_session_endpoint': logoutUri.toString(),
    'response_types_supported': ['code'],
    'subject_types_supported': ['public'],
    'id_token_signing_alg_values_supported': ['RS256'],
    'code_challenge_methods_supported': ['S256'],
    'scopes_supported': ['openid', 'profile', 'email', 'offline_access'],
    'grant_types_supported': ['authorization_code', 'refresh_token'],
  };

  /// An RS256 ID token for [fakeSubject] that expires [ttl] from now, with [nonce] when given.
  String signIdToken({String? nonce, Duration ttl = const Duration(hours: 1)}) {
    final now = clock.now();
    final builder = JsonWebSignatureBuilder()
      ..jsonContent = {
        'iss': issuer,
        'sub': fakeSubject,
        'aud': audience,
        'exp': now.add(ttl).millisecondsSinceEpoch ~/ 1000,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'nonce': ?nonce,
        'preferred_username': 'person',
        'realm_access': {
          'roles': ['admin'],
        },
      }
      ..addRecipient(signWithForeignKey ? _foreignKey : _signingKey, algorithm: 'RS256');
    return builder.build().toCompactSerialization();
  }

  /// A token endpoint answer: a new access and refresh token, an ID token unless [idToken] is false, and [expiresIn].
  http.Response tokenAnswer({bool idToken = true, String? nonce, String? accessToken}) {
    _counter++;
    return json({
      'access_token': accessToken ?? 'access-$_counter-value',
      'refresh_token': 'refresh-$_counter-value',
      if (idToken) 'id_token': signIdToken(nonce: nonce),
      'token_type': 'Bearer',
      'expires_in': ?expiresIn,
    });
  }

  /// An RFC 6749 error answer such as `invalid_grant`.
  static http.Response errorAnswer(String error, {int status = 400}) =>
      json({'error': error, 'error_description': 'The provider says no'}, status: status);

  static http.Response json(Object body, {int status = 200}) =>
      http.Response(jsonEncode(body), status, headers: const {'content-type': 'application/json'});

  Future<http.Response> _answer(http.Request request) async {
    requests.add(request);
    final url = request.url;
    if (url == discoveryUri) return await discoveryAnswer?.call() ?? json(discovery);
    if (url.path.endsWith('/certs')) {
      if (jwksAnswer case final answer?) return answer();
      final public = Map<String, dynamic>.of(_signingKey.toJson())
        ..removeWhere((key, _) => const {'d', 'p', 'q', 'dp', 'dq', 'qi'}.contains(key));
      return json({
        'keys': [public],
      });
    }
    if (url == tokenUri) {
      return switch (form(request)['grant_type']) {
        'authorization_code' => await codeAnswer?.call() ?? tokenAnswer(nonce: nonce),
        'refresh_token' => await refreshAnswer?.call() ?? tokenAnswer(idToken: refreshReturnsIdToken),
        final grant => throw StateError('the fake provider does not answer grant_type $grant'),
      };
    }
    return http.Response('not found', 404);
  }
}

/// How [FakeOidcPlatform] answers an authorization request.
enum FakeAuthorization {
  /// Redirects back with a code.
  code,

  /// The user closed the browser: the platform answers null.
  cancel,

  /// Redirects back with `error=access_denied`.
  accessDenied,

  /// Answers null, as the same-tab web navigation does.
  navigateAway,

  /// Waits until [FakeOidcPlatform.completePending] answers.
  pending,
}

/// How [FakeOidcPlatform] answers an end-session request.
enum FakeEndSession { ended, nullAnswer, fails, pending }

/// An [OidcPlatform] that answers the browser round trips without a browser, and records what it was asked.
final class FakeOidcPlatform extends OidcPlatform {
  FakeOidcPlatform(this.provider);

  final FakeProvider provider;

  FakeAuthorization authorization = FakeAuthorization.code;
  FakeEndSession endSession = FakeEndSession.ended;

  final authorizeRequests = <OidcAuthorizeRequest>[];
  final authorizeOptions = <OidcPlatformSpecificOptions>[];
  final endSessionRequests = <OidcEndSessionRequest>[];
  final endSessionMetadata = <OidcProviderMetadata>[];
  final endSessionOptions = <OidcPlatformSpecificOptions>[];

  Completer<Object?>? _pending;

  /// Whether an authorization or end-session request waits for [completePending].
  bool get hasPending => _pending != null && !_pending!.isCompleted;

  /// Answers the pending request with null, as the platform does when the flow is cancelled.
  void completePending() => _pending!.complete(null);

  /// The authorization URL of the last request.
  Uri get lastAuthorizeUri => authorizeRequests.last.generateUri(Uri.parse('${provider.issuer}/auth'));

  @override
  Map<String, dynamic> prepareForRedirectFlow(OidcPlatformSpecificOptions options) => const {};

  @override
  Future<OidcAuthorizeResponse?> getAuthorizationResponse(
    OidcProviderMetadata metadata,
    OidcAuthorizeRequest request,
    OidcPlatformSpecificOptions options,
    Map<String, dynamic> preparationResult,
  ) async {
    authorizeRequests.add(request);
    authorizeOptions.add(options);
    provider.nonce = request.nonce;
    switch (authorization) {
      case FakeAuthorization.cancel || FakeAuthorization.navigateAway:
        return null;
      case FakeAuthorization.pending:
        final pending = _pending = Completer<Object?>();
        await pending.future;
        return null;
      case FakeAuthorization.code:
        return redirect(request, {'code': 'code-value', 'state': request.state!});
      case FakeAuthorization.accessDenied:
        return redirect(request, {'error': 'access_denied', 'state': request.state!});
    }
  }

  /// Parses the redirect to [request] that carries [parameters], as a platform does.
  static Future<OidcAuthorizeResponse> redirect(OidcAuthorizeRequest request, Map<String, String> parameters) =>
      OidcEndpoints.parseAuthorizeResponse(
        responseUri: request.redirectUri.replace(queryParameters: parameters),
        overrides: {'redirect_uri': request.redirectUri.toString()},
      );

  @override
  Future<OidcEndSessionResponse?> getEndSessionResponse(
    OidcProviderMetadata metadata,
    OidcEndSessionRequest request,
    OidcPlatformSpecificOptions options,
    Map<String, dynamic> preparationResult,
  ) async {
    endSessionRequests.add(request);
    endSessionMetadata.add(metadata);
    endSessionOptions.add(options);
    switch (endSession) {
      case FakeEndSession.ended:
        return OidcEndSessionResponse.fromJson(const {});
      case FakeEndSession.nullAnswer:
        return null;
      case FakeEndSession.fails:
        throw const OidcException('Native endSession failed (BROWSER_ERROR): no browser');
      case FakeEndSession.pending:
        final pending = _pending = Completer<Object?>();
        await pending.future;
        return null;
    }
  }

  /// The end-session URL of the last request.
  Uri get lastEndSessionUri => endSessionRequests.last.generateUri(endSessionMetadata.last.endSessionEndpoint!);

  @override
  Stream<OidcFrontChannelLogoutIncomingRequest> listenToFrontChannelLogoutRequests(
    Uri listenOn,
    OidcFrontChannelRequestListeningOptions options,
  ) => const Stream.empty();

  @override
  Stream<OidcMonitorSessionResult> monitorSessionStatus({
    required Uri checkSessionIframe,
    required OidcMonitorSessionStatusRequest request,
  }) => const Stream.empty();
}

/// Installs a [FakeOidcPlatform] for [provider] until the test ends, then restores the no-op platform and clears the
/// package's per-issuer JWKS refetch limit, which would otherwise carry over to the next test.
FakeOidcPlatform installFakePlatform(FakeProvider provider) {
  final platform = FakeOidcPlatform(provider);
  OidcPlatform.instance = platform;
  addTearDown(() {
    OidcPlatform.instance = NoOpOidcPlatform();
    jwksForceRefetchTimestamps.clear();
  });
  return platform;
}
