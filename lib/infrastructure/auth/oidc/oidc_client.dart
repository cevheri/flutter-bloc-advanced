import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:http/http.dart' as http;
import 'package:oidc/oidc.dart';

import 'app_oidc_user_manager.dart';
import 'oidc_page_restore.dart';
import 'oidc_redirect_uris.dart';
import 'oidc_transaction_store.dart';

/// The tokens of a sign-in.
final class OidcTokens {
  const OidcTokens({
    required this.accessToken,
    required this.idToken,
    required this.accessTokenExpiresAt,
    this.refreshToken,
  });

  final String accessToken;
  final String idToken;

  /// Null when the provider issued none.
  final String? refreshToken;

  /// When [accessToken] expires, in UTC, from the answer's `expires_in`.
  final DateTime accessTokenExpiresAt;

  /// Masks every token, so a log line that prints the tokens does not print a credential.
  @override
  String toString() =>
      'OidcTokens(accessToken: ${maskToken(accessToken)}, idToken: ${maskToken(idToken)}, '
      'refreshToken: ${maskToken(refreshToken)}, accessTokenExpiresAt: $accessTokenExpiresAt)';
}

/// Why a sign-in failed.
enum OidcFailure {
  /// The provider could not be reached: discovery, the JWKS or the token endpoint, or a transport failure.
  discovery,

  /// The provider answered with an error, or its answer did not pass a check.
  failed,
}

/// How a sign-in ended.
sealed class OidcSignInOutcome {
  const OidcSignInOutcome();
}

/// The user signed in. [claims] are the claims of the verified ID token.
final class OidcSignedIn extends OidcSignInOutcome {
  const OidcSignedIn({required this.tokens, required this.claims});

  final OidcTokens tokens;
  final Map<String, Object?> claims;
}

/// The user left the provider page without signing in.
final class OidcSignInCancelled extends OidcSignInOutcome {
  const OidcSignInCancelled();
}

final class OidcSignInFailed extends OidcSignInOutcome {
  const OidcSignInFailed(this.failure);

  final OidcFailure failure;
}

/// The web tab is on its way to the provider; the sign-in completes after the tab comes back, through
/// [IOidcClient.completePendingSignIn].
final class OidcSignInNavigatedAway extends OidcSignInOutcome {
  const OidcSignInNavigatedAway();
}

/// How a provider logout ended.
sealed class OidcLogoutOutcome {
  const OidcLogoutOutcome();
}

final class ProviderSessionEnded extends OidcLogoutOutcome {
  const ProviderSessionEnded();
}

/// The provider has no logout endpoint, so only the app session ends.
final class NoProviderLogout extends OidcLogoutOutcome {
  const NoProviderLogout();
}

/// The provider logout could not be opened, the user cancelled it, or the provider answered with an error.
final class ProviderLogoutFailed extends OidcLogoutOutcome {
  const ProviderLogoutFailed();
}

/// The web tab is on its way to the provider's logout page.
final class ProviderLogoutNavigatedAway extends OidcLogoutOutcome {
  const ProviderLogoutNavigatedAway();
}

/// The OpenID Connect protocol of an `oidc` build: sign-in, the same-tab web completion, refresh and provider logout.
abstract interface class IOidcClient {
  /// Signs the user in through the provider's page. On web the tab leaves for the provider, and the answer is
  /// [OidcSignInNavigatedAway]; [webReturnPath] is where the tab lands when it comes back. [browserDoneMessage] is the
  /// page a desktop browser shows once the app has the answer.
  Future<OidcSignInOutcome> signIn({String? webReturnPath, required String browserDoneMessage});

  /// Completes a same-tab web sign-in from the transaction store after the tab came back from the provider. Null when
  /// nothing is pending; until then it reads only the store.
  Future<OidcSignInOutcome?> completePendingSignIn();

  /// Trades [refreshToken] for new tokens at the provider's token endpoint. The stored session's tokens are handed to
  /// the package for this one call; [idToken] may have expired.
  Future<TokenRotationResult> refresh({
    required String refreshToken,
    required String idToken,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  });

  /// Ends the user's session at the provider, sending [idTokenHint] as `id_token_hint` when it is given.
  Future<OidcLogoutOutcome> endProviderSession({String? idTokenHint});
}

/// [IOidcClient] over the oidc package's user manager.
///
/// One [AppOidcUserManager] serves the whole run. It is created on first use, and a failed `init()` drops it, so the
/// next call fetches discovery again. Each sign-in, web completion and refresh ends with the manager forgetting its
/// user and the store dropping this tab's transaction, so the app's session storage is the only place tokens live.
/// The one exception is the web tap: the state and the PKCE verifier must stay for `web/redirect.html` and for the
/// tab that comes back.
///
/// The operations run one at a time, each after the previous one has ended, because they share the manager: a code
/// exchange that lands while a refresh holds the adopted user would replace that user's token, whose ID token the
/// package then reads without checking the signature, and the provider error flag would belong to two operations.
final class OidcClient implements IOidcClient {
  /// [launchUrl] opens the browser on Linux and Windows. It must throw rather than answer false, since the package
  /// logs the authorization URL when a launcher answers false. [pageUri] is the page a web build runs in, which the
  /// web redirect URIs are built from; it defaults to `Uri.base`. [reloadOnPageRestore] registers the web page's
  /// back-forward cache listener, `reloadWhenRestoredFromCache` by default. [onManagerCreated] lets a test see each
  /// manager the client builds.
  OidcClient({
    required this._settings,
    required this._loginPath,
    required this._launchUrl,
    OidcTransactionStore? store,
    http.Client? httpClient,
    OidcPlatformKind? platform,
    Uri? pageUri,
    Future<void> Function()? cancelAndroidFlow,
    void Function()? reloadOnPageRestore,
    @visibleForTesting this._onManagerCreated,
  }) : _store = store ?? OidcTransactionStore.forPlatform(),
       _http = _ProviderHttpClient(httpClient ?? http.Client()),
       _platform = platform ?? OidcPlatformKind.current(),
       _pageUri = pageUri ?? Uri.base,
       _cancelAndroidFlow = cancelAndroidFlow ?? (() => OidcAndroidHostApi().cancel()),
       _reloadOnPageRestore = reloadOnPageRestore ?? reloadWhenRestoredFromCache;

  static final _log = AppLogger.getLogger('OidcClient');

  /// How long a Linux or Windows sign-in waits for the browser. The package has no way to cancel the loopback
  /// listener, so a user who closes the browser can sign in again only after this.
  static const _desktopFlowTimeoutSeconds = 300;

  /// The page a desktop browser shows after a logout. A provider logout takes no message, and the package's default
  /// page sends the browser to google.com.
  static const _blankPage =
      '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body></body></html>';

  final OidcSettings _settings;
  final String _loginPath;
  final Future<bool> Function(Uri) _launchUrl;
  final OidcTransactionStore _store;
  final _ProviderHttpClient _http;
  final OidcPlatformKind _platform;
  final Uri _pageUri;
  final Future<void> Function() _cancelAndroidFlow;
  final void Function() _reloadOnPageRestore;
  final void Function(AppOidcUserManager manager)? _onManagerCreated;

  late final _redirectUris = OidcRedirectUris.forPlatform(_settings, platform: _platform, pageUri: _pageUri);

  /// The run's manager once its `init()` has started, or null before that and after a failed `init()`.
  Future<AppOidcUserManager>? _ready;

  /// Whether the web page's back-forward cache listener is registered; one serves the whole run.
  bool _watchingPageRestore = false;

  /// Completes when the last operation queued has ended, whatever its result.
  Future<void> _idle = Future<void>.value();

  /// Runs [operation] after every operation queued before it has ended. Its result and its error reach the caller
  /// unchanged; the queue only waits for it.
  Future<T> _oneAtATime<T>(Future<T> Function() operation) {
    final result = _idle.then((_) => operation());
    _idle = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<OidcSignInOutcome> signIn({String? webReturnPath, required String browserDoneMessage}) =>
      _oneAtATime(() => _signIn(webReturnPath: webReturnPath, browserDoneMessage: browserDoneMessage));

  Future<OidcSignInOutcome> _signIn({String? webReturnPath, required String browserDoneMessage}) async {
    _http.getFailed = false;
    final AppOidcUserManager manager;
    try {
      manager = await _initializedManager();
    } on Object catch (error) {
      _log.warn('The identity provider could not be reached to sign in: {}', [() => _describe(error)]);
      return const OidcSignInFailed(OidcFailure.discovery);
    }
    final options = _platformOptions(successfulPageResponse: _browserDonePage(browserDoneMessage));
    if (_platform == OidcPlatformKind.web) return _startWebSignIn(manager, options, webReturnPath);

    final lifecycle = _cancelOnResume();
    try {
      final user = await manager.loginAuthorizationCodeFlow(includeIdTokenHintFromCurrentUser: false, options: options);
      if (user == null) {
        if (!manager.authorizationResponseReceived) {
          _log.info('The sign-in was cancelled at the identity provider');
          return const OidcSignInCancelled();
        }
        _log.warn('The ID token of the sign-in failed a claim check');
        return const OidcSignInFailed(OidcFailure.failed);
      }
      return _signedIn(user);
    } on Object catch (error) {
      return _signInFailed(error, manager);
    } finally {
      lifecycle?.dispose();
      await _store.clearTransactions();
      await manager.forgetUser();
    }
  }

  /// Writes the transaction and sends the tab to the provider. The package answers null once the navigation has
  /// started; the transaction stays in the store for the tab that comes back.
  ///
  /// The login page stays in its loading state after the tab leaves, so the page is reloaded when the browser brings
  /// it back from the back-forward cache: the reload's startup step then reports the abandoned sign-in as a cancel.
  Future<OidcSignInOutcome> _startWebSignIn(
    AppOidcUserManager manager,
    OidcPlatformSpecificOptions options,
    String? webReturnPath,
  ) async {
    if (!_watchingPageRestore) {
      _reloadOnPageRestore();
      _watchingPageRestore = true;
    }
    final OidcUser? user;
    try {
      user = await manager.loginAuthorizationCodeFlow(
        originalUri: webAppEntryUri(_pageUri, returnPath: webReturnPath, loginPath: _loginPath),
        includeIdTokenHintFromCurrentUser: false,
        options: options,
      );
    } on Object catch (error) {
      await _store.clearTransactions();
      await manager.forgetUser();
      return _signInFailed(error, manager);
    }
    if (user != null) {
      await _store.clearTransactions();
      await manager.forgetUser();
      throw StateError('The same-tab web sign-in answered a user instead of leaving the page');
    }
    return const OidcSignInNavigatedAway();
  }

  @override
  Future<OidcSignInOutcome?> completePendingSignIn() => _oneAtATime(_completePendingSignIn);

  Future<OidcSignInOutcome?> _completePendingSignIn() async {
    // A verifier with no response: the tab left for the provider and came back without an answer (Back button).
    if (_store.hasAbandonedSignIn()) {
      await _store.clearTransactions();
      _log.info('The tab came back from the identity provider without an answer, so the sign-in is cancelled');
      return const OidcSignInCancelled();
    }
    final bool pending;
    try {
      pending = await _store.hasPendingResponse();
    } on FormatException {
      // A malformed index would fail every later sign-in too, since the manager's init() reads it; clearing removes it.
      await _store.clearTransactions();
      rethrow;
    }
    if (!pending) return null;

    _http.getFailed = false;
    // The manager's init() exchanges the stored response. A manager that already ran init() in this run would not
    // read the store again, so the completion always starts a new one, which then serves the rest of the run.
    final replaced = _ready;
    final manager = _newManager();
    try {
      // The queue lets no other operation use the replaced manager any more, and a manager in _ready is initialized.
      await (await replaced)?.dispose();
      await _initialize(manager);
      final user = manager.currentUser;
      if (user == null) {
        _log.warn('The ID token of the web sign-in failed a claim check');
        return const OidcSignInFailed(OidcFailure.failed);
      }
      return _signedIn(user);
    } on Object catch (error) {
      return _signInFailed(error, manager);
    } finally {
      // The package keeps the state and the response of an error answer, which every later init() would fail on
      // again, and it keeps the verifier, which would make the next start look like an abandoned sign-in.
      await _store.clearTransactions();
      await manager.forgetUser();
    }
  }

  /// [accessTokenExpiresAt] is not handed to the package: the adopted session carries no `expires_in`, so the
  /// refreshed expiry comes only from the provider's answer, and is null when the answer has none.
  @override
  Future<TokenRotationResult> refresh({
    required String refreshToken,
    required String idToken,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) => _oneAtATime(() => _refresh(refreshToken: refreshToken, idToken: idToken, accessToken: accessToken));

  Future<TokenRotationResult> _refresh({
    required String refreshToken,
    required String idToken,
    required String accessToken,
  }) async {
    _http.getFailed = false;
    final AppOidcUserManager manager;
    try {
      manager = await _initializedManager();
    } on Object catch (error) {
      // Nothing was sent yet, so the refresh token is still good: keep the session.
      _log.warn('The identity provider could not be reached to refresh: {}', [() => _describe(error)]);
      return const RotationUnavailable();
    }
    try {
      try {
        await manager.adoptSession(idToken: idToken, accessToken: accessToken, refreshToken: refreshToken);
      } on Object catch (error) {
        _log.error('The stored ID token could not be read, so the session cannot be refreshed: {}', [
          () => _describe(error),
        ]);
        return const RotationRefused();
      }
      final user = await manager.refreshAdoptedSession();
      if (user == null) {
        _log.warn('The refreshed ID token failed a claim check');
        return const RotationRefused();
      }
      final newAccessToken = user.token.accessToken;
      if (newAccessToken == null || newAccessToken.isEmpty) {
        _log.warn('The refresh answer has no access token');
        return const RotationRefused();
      }
      var idTokenChecked = true;
      // The flag now notes only the JWKS fetch.
      _http.getFailed = false;
      try {
        await manager.verifyRefreshedIdToken(user);
      } on Object catch (error) {
        // A signature that does not verify against keys the provider served ends the session. Keys that could not be
        // fetched say nothing about the token, and the provider has already traded the refresh token, so it must not
        // be sent again: the new tokens are kept, and the unchecked ID token is dropped so the stored one stays.
        if (!_http.getFailed && !_isTransportError(error)) rethrow;
        _log.warn(
          'The keys of the identity provider could not be fetched to check the refreshed ID token, so the '
          'stored ID token is kept: {}',
          [() => _describe(error)],
        );
        idTokenChecked = false;
      }
      return TokensRotated(
        accessToken: newAccessToken,
        refreshToken: _nonEmpty(user.token.refreshToken),
        oidcIdToken: !idTokenChecked || user.token.idTokenRetainedFromPriorResponse ? null : _nonEmpty(user.idToken),
        accessTokenExpiresAt: user.token.calculateExpiresAt()?.toUtc(),
      );
    } on Object catch (error) {
      return _refreshFailed(error);
    } finally {
      await _store.clearTransactions();
      await manager.forgetUser();
    }
  }

  @override
  Future<OidcLogoutOutcome> endProviderSession({String? idTokenHint}) =>
      _oneAtATime(() => _endProviderSession(idTokenHint: idTokenHint));

  Future<OidcLogoutOutcome> _endProviderSession({String? idTokenHint}) async {
    try {
      final manager = await _initializedManager();
      final endpoint = _logoutEndpoint(manager.discoveryDocument);
      if (endpoint == null) {
        _log.info('The identity provider has no logout endpoint, so only the app session ended');
        return const NoProviderLogout();
      }
      final options = _platformOptions(successfulPageResponse: _blankPage);
      final OidcEndSessionResponse? response;
      final lifecycle = _cancelOnResume();
      try {
        response = await OidcFlutter.getPlatformEndSessionResponse(
          metadata: endpoint.metadata,
          request: OidcEndSessionRequest(
            clientId: _settings.clientId,
            postLogoutRedirectUri: _redirectUris.postLogout,
            idTokenHint: idTokenHint,
            extra: endpoint.extra,
          ),
          options: options,
          preparationResult: OidcFlutter.prepareForRedirectFlow(options),
        );
      } finally {
        lifecycle?.dispose();
      }
      if (_platform == OidcPlatformKind.web) return const ProviderLogoutNavigatedAway();
      if (response == null) {
        _log.warn('The provider logout was cancelled');
        return const ProviderLogoutFailed();
      }
      return const ProviderSessionEnded();
    } on Object catch (error) {
      _log.warn('The provider logout failed: {}', [() => _describe(error)]);
      return const ProviderLogoutFailed();
    }
  }

  /// The discovered `end_session_endpoint`; otherwise Auth0's `/v2/logout`, which takes `returnTo`, for an issuer on
  /// `auth0.com`; otherwise null.
  ({OidcProviderMetadata metadata, Map<String, dynamic>? extra})? _logoutEndpoint(OidcProviderMetadata discovered) {
    if (discovered.endSessionEndpoint != null) return (metadata: discovered, extra: null);
    final host = _settings.issuer.host;
    if (host != 'auth0.com' && !host.endsWith('.auth0.com')) return null;
    final auth0Logout = _settings.issuer.replace(path: '/v2/logout');
    return (
      metadata: OidcProviderMetadata.fromJson({...discovered.src, 'end_session_endpoint': auth0Logout.toString()}),
      extra: {'returnTo': _redirectUris.postLogout.toString()},
    );
  }

  Future<AppOidcUserManager> _initializedManager() => _ready ?? _initialize(_newManager());

  /// Runs [manager]'s `init()` and makes it the run's manager, or disposes and drops it when `init()` fails: the
  /// package cannot retry `init()` on the same instance.
  Future<AppOidcUserManager> _initialize(AppOidcUserManager manager) async {
    final ready = _ready = manager.init().then((_) => manager);
    try {
      return await ready;
    } on Object {
      if (identical(_ready, ready)) _ready = null;
      await manager.dispose();
      rethrow;
    }
  }

  AppOidcUserManager _newManager() {
    final manager = _buildManager();
    _onManagerCreated?.call(manager);
    return manager;
  }

  AppOidcUserManager _buildManager() => AppOidcUserManager.lazy(
    discoveryDocumentUri: OidcUtils.getOpenIdConfigWellKnownUri(_settings.issuer),
    clientCredentials: OidcClientAuthentication.none(clientId: _settings.clientId),
    store: _store,
    httpClient: _http,
    settings: OidcUserManagerSettings(
      redirectUri: _redirectUris.signIn,
      postLogoutRedirectUri: _redirectUris.postLogout,
      scope: _settings.scopes,
      prompt: [?_settings.prompt.parameter],
      extraAuthenticationParameters: {'audience': ?_settings.audience},
      refreshBefore: null,
      // Roles come from the ID token. The package logs the whole UserInfo answer.
      userInfoSettings: const OidcUserInfoSettings(sendUserInfoRequest: false),
      revokeTokensOnLogout: false,
      supportOfflineAuth: false,
      initMode: OidcInitMode.blockingValidate,
      discoveryDocumentMaxAge: const Duration(minutes: 5),
      options: _platformOptions(successfulPageResponse: _blankPage),
    ),
  );

  /// The browser of every platform: a Custom Tab on Android, the shared browser session on iOS and macOS, the same
  /// tab on web, and [_launchUrl] with a loopback listener on Linux and Windows, which shows [successfulPageResponse].
  OidcPlatformSpecificOptions _platformOptions({required String successfulPageResponse}) {
    final desktop = OidcPlatformSpecificOptions_Native(
      launchUrl: _launchUrl,
      successfulPageResponse: successfulPageResponse,
      flowTimeoutSeconds: _desktopFlowTimeoutSeconds,
    );
    return OidcPlatformSpecificOptions(
      android: const OidcNativeOptionsAndroid(useAuthTab: OidcAuthTabMode.never),
      ios: const OidcNativeOptionsApple(),
      macos: const OidcNativeOptionsApple(),
      web: const OidcPlatformSpecificOptions_Web(
        navigationMode: OidcPlatformSpecificOptions_Web_NavigationMode.samePage,
      ),
      linux: desktop,
      windows: desktop,
    );
  }

  static String _browserDonePage(String message) =>
      '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head>'
      '<body><p>${htmlEscape.convert(message)}</p></body></html>';

  /// On Android, cancels the pending browser flow whenever the app comes back to the foreground. A closed Custom Tab
  /// tells the app nothing, so without this the flow would wait forever. After a redirect the plugin has already
  /// finished the flow, and the cancel does nothing.
  AppLifecycleListener? _cancelOnResume() {
    if (_platform != OidcPlatformKind.android) return null;
    return AppLifecycleListener(
      onResume: () => unawaited(
        _cancelAndroidFlow().catchError(
          (Object error) =>
              _log.error('The pending Android browser flow could not be cancelled: {}', [() => _describe(error)]),
        ),
      ),
    );
  }

  OidcSignInOutcome _signedIn(OidcUser user) {
    final accessToken = user.token.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _log.warn('The token answer of the sign-in has no access token');
      return const OidcSignInFailed(OidcFailure.failed);
    }
    if (user.idToken.isEmpty) {
      _log.warn('The token answer of the sign-in has no ID token');
      return const OidcSignInFailed(OidcFailure.failed);
    }
    final expiresAt = user.token.calculateExpiresAt();
    if (expiresAt == null) {
      _log.warn('The token answer of the sign-in has no expires_in, so the session would never be refreshed');
      return const OidcSignInFailed(OidcFailure.failed);
    }
    return OidcSignedIn(
      tokens: OidcTokens(
        accessToken: accessToken,
        idToken: user.idToken,
        refreshToken: _nonEmpty(user.token.refreshToken),
        accessTokenExpiresAt: expiresAt.toUtc(),
      ),
      claims: Map.of(user.claims.toJson())..removeWhere((name, _) => _protocolClaims.contains(name)),
    );
  }

  /// ID token claims that only bind the token to this sign-in. The `nonce` must never reach a log line, and a caller
  /// needs none of them.
  static const _protocolClaims = {'nonce', 'at_hash', 'c_hash'};

  /// A transport failure, or a discovery or JWKS failure, is [OidcFailure.discovery]; an error answer or a failed
  /// check, such as a bad signature or a nonce mismatch, is [OidcFailure.failed]. A Linux or Windows browser step that
  /// timed out is the user not finishing at the provider, so it is a cancel.
  OidcSignInOutcome _signInFailed(Object error, AppOidcUserManager manager) {
    if (manager.browserFlowTimedOut) {
      _log.info('The sign-in was not finished in the browser within {} seconds, so it is cancelled', [
        _desktopFlowTimeoutSeconds,
      ]);
      return const OidcSignInCancelled();
    }
    final failure = !manager.discoveryLoaded || _http.getFailed || _isTransportError(error)
        ? OidcFailure.discovery
        : OidcFailure.failed;
    _log.warn('The sign-in failed ({}): {}', [failure.name, () => _describe(error)]);
    return OidcSignInFailed(failure);
  }

  /// The provider refusing, or a refreshed ID token failing a check, ends the session; the provider being out of
  /// reach keeps it. A GET error status comes first, and so does a token endpoint status of 429 or 5xx, whatever its
  /// error code. The JWKS of a refreshed ID token is handled before this, since its grant has already been answered.
  TokenRotationResult _refreshFailed(Object error) {
    final TokenRotationResult result;
    final status = error is OidcException ? error.rawResponse?.statusCode : null;
    if (_http.getFailed) {
      result = const RotationUnavailable();
    } else if (status != null && (status == 429 || status >= 500)) {
      // Too many requests, or the provider failing, says nothing about the refresh token, whatever the error code.
      result = const RotationUnavailable();
    } else if (error is JoseException) {
      result = const RotationRefused();
    } else {
      result = switch (OidcOfflineAuthErrorHandler.categorizeError(error)) {
        OfflineAuthErrorType.networkUnavailable ||
        OfflineAuthErrorType.networkTimeout ||
        OfflineAuthErrorType.sslError ||
        OfflineAuthErrorType.serverError => const RotationUnavailable(),
        OfflineAuthErrorType.authenticationError || OfflineAuthErrorType.clientError => const RotationRefused(),
        OfflineAuthErrorType.unknown =>
          _isTransportError(error) ? const RotationUnavailable() : const RotationRefused(),
      };
    }
    _log.warn('The refresh failed ({}): {}', [result.runtimeType, () => _describe(error)]);
    return result;
  }

  /// Whether [error], or the error an [OidcException] wraps, is a transport failure: no network, a timeout or TLS.
  static bool _isTransportError(Object error) {
    final cause = error is OidcException ? error.internalException ?? error : error;
    return switch (OidcOfflineAuthErrorHandler.categorizeError(cause)) {
      OfflineAuthErrorType.networkUnavailable ||
      OfflineAuthErrorType.networkTimeout ||
      OfflineAuthErrorType.sslError => true,
      _ => false,
    };
  }

  /// The type of [error] and, for an [OidcException], the provider's error code and status. Never its message, its
  /// request or its response, which can carry a token, the code, the verifier or a URL with `state`.
  static String _describe(Object error) => switch (error) {
    OidcException(:final errorResponse, :final rawResponse, :final internalException) =>
      'OidcException(error: ${errorResponse?.error}, status: ${rawResponse?.statusCode}, '
          'cause: ${internalException?.runtimeType})',
    _ => '${error.runtimeType}',
  };

  static String? _nonEmpty(String? value) => value == null || value.isEmpty ? null : value;
}

/// Passes the requests to the provider on, and notes a GET the provider answers with an error status. Discovery runs
/// inside the manager's `init()`, so during a sign-in or a refresh the only GET is the JWKS, whose failure the
/// package does not report as such: jose_plus parses the error page as a key set.
final class _ProviderHttpClient extends http.BaseClient {
  _ProviderHttpClient(this._inner);

  final http.Client _inner;

  /// Whether a GET answered with a status of 400 or more since the flag was last cleared.
  bool getFailed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (request.method == 'GET' && response.statusCode >= 400) getFailed = true;
    return response;
  }
}
