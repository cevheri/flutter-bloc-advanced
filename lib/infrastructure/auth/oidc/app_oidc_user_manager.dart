import 'package:clock/clock.dart';
import 'package:oidc/oidc.dart';

/// The oidc package's user manager with every background behavior switched off, so it runs one protocol step at a
/// time for `OidcClient` and holds a user only for the length of that step.
///
/// `TokenRefreshInterceptor` is the only owner of refresh: the manager never arms the expiring or the expired timer,
/// so it never refreshes, or forgets a user, on its own.
final class AppOidcUserManager extends OidcUserManager {
  AppOidcUserManager.lazy({
    required super.discoveryDocumentUri,
    required super.clientCredentials,
    required super.store,
    required super.settings,
    super.httpClient,
  }) : super.lazy();

  bool _responseReceived = false;
  bool _discoveryLoaded = false;

  /// Whether the last sign-in got an authorization response from the platform. The manager answers null both for a
  /// cancel, which has no response, and for an ID token that fails a claim check after one.
  bool get authorizationResponseReceived => _responseReceived;

  /// Whether `init()` got as far as a valid discovery document, which tells a discovery failure of the same-tab web
  /// completion apart from a failure of its code exchange: both happen inside `init()`.
  bool get discoveryLoaded => _discoveryLoaded;

  @override
  Future<void> listenToTokenRefreshIfSupported(OidcTokenEventsManager tokenEventsManager, OidcUser? user) async {}

  /// A sign-in that has not come back within 5 minutes is dropped, instead of after the package's 1 day.
  @override
  Future<void> clearUnusedStates() => OidcState.clearStaleState(store: store, age: const Duration(minutes: 5));

  @override
  Future<void> ensureDiscoveryDocument() async {
    await super.ensureDiscoveryDocument();
    _discoveryLoaded = true;
  }

  @override
  Future<OidcAuthorizeResponse?> getAuthorizationResponse(
    OidcProviderMetadata metadata,
    OidcAuthorizeRequest request,
    OidcPlatformSpecificOptions options,
    Map<String, dynamic> preparationResult,
  ) async {
    _responseReceived = false;
    final response = await super.getAuthorizationResponse(metadata, request, options, preparationResult);
    _responseReceived = response != null;
    return response;
  }

  /// Makes the stored session the current user, for one refresh.
  ///
  /// The ID token is parsed without verification, as the package's own restore of a cached session does: it was
  /// verified when it was issued, and it may have expired since. The token carries no `expires_in`, so the refreshed
  /// token's expiry comes only from the provider's answer.
  Future<void> adoptSession({
    required String idToken,
    required String accessToken,
    required String? refreshToken,
  }) async {
    final token = OidcToken(
      creationTime: clock.now().toUtc(),
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: 'Bearer',
    );
    userSubject.add(await OidcUser.fromIdToken(token: token));
  }

  /// Refreshes the adopted session, and verifies the signature of a new ID token against the provider's keys.
  ///
  /// The package re-verifies a refreshed ID token only with the keys of the user it replaces, and the adopted user,
  /// parsed without verification, has none. Throws [JoseException] when the signature does not verify. Returns null
  /// when the new ID token fails a claim check.
  Future<OidcUser?> refreshAdoptedSession() async {
    final user = await refreshToken();
    if (user == null || user.token.idTokenRetainedFromPriorResponse) return user;
    await OidcUser.fromIdToken(
      token: user.token,
      keystore: keyStore,
      cacheStore: store,
      allowedAlgorithms: resolveAllowedIdTokenAlgorithms(discoveryDocument),
      jwksCacheMaxAge: settings.jwksCacheMaxAge,
      httpClient: httpClient,
    );
    return user;
  }
}
