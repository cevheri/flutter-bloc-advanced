import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/app_oidc_user_manager.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_key_value.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_redirect_uris.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_transaction_store.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oidc/oidc.dart';

import 'support/fake_provider.dart';

const _loginPath = '/login';
const _doneMessage = 'Signed in. You can close this tab & go back to <the app>.';
final _pageUri = Uri.parse('http://localhost:8081/');

void main() {
  late FakeProvider provider;
  late FakeOidcPlatform platform;
  late MemoryKeyValue persistent;
  late MemoryKeyValue tab;
  late OidcTransactionStore store;
  late List<Uri> launchedUrls;

  setUp(() {
    provider = FakeProvider();
    platform = installFakePlatform(provider);
    persistent = MemoryKeyValue();
    tab = MemoryKeyValue();
    store = OidcTransactionStore(persistent: persistent, tab: tab);
    launchedUrls = [];
  });

  OidcSettings settingsFor(FakeProvider provider, {String? audience, OidcPrompt prompt = OidcPrompt.login}) =>
      OidcSettings(issuer: Uri.parse(provider.issuer), clientId: fakeClientId, audience: audience, prompt: prompt);

  OidcClient newClient({
    OidcSettings? settings,
    OidcPlatformKind platformKind = OidcPlatformKind.ios,
    OidcTransactionStore? transactionStore,
    FakeProvider? at,
    Future<void> Function()? cancelAndroidFlow,
    void Function(AppOidcUserManager manager)? onManagerCreated,
    void Function()? reloadOnPageRestore,
  }) {
    final idp = at ?? provider;
    return OidcClient(
      settings: settings ?? settingsFor(idp),
      loginPath: _loginPath,
      launchUrl: (uri) async {
        launchedUrls.add(uri);
        return true;
      },
      store: transactionStore ?? store,
      httpClient: idp.client,
      platform: platformKind,
      pageUri: _pageUri,
      cancelAndroidFlow: cancelAndroidFlow ?? () async => fail('cancelAndroidFlow was not expected'),
      onManagerCreated: onManagerCreated,
      reloadOnPageRestore: reloadOnPageRestore,
    );
  }

  Future<OidcSignInOutcome> signIn(OidcClient client) =>
      client.signIn(webReturnPath: '/users', browserDoneMessage: _doneMessage);

  Future<void> expectStoreEmpty() async {
    expect(await store.getAllKeys(OidcStoreNamespace.state), isEmpty, reason: 'states left in the store');
    expect(await store.getAllKeys(OidcStoreNamespace.stateResponse), isEmpty, reason: 'responses left in the store');
    expect(await store.getAllKeys(OidcStoreNamespace.secureTokens), isEmpty, reason: 'secure keys left in the store');
  }

  group('signIn', () {
    test('success gives OidcSignedIn with the tokens, the claims and an expiry of now + expires_in', () async {
      provider.expiresIn = 120;
      final before = clock.now().toUtc();

      final outcome = await signIn(newClient());

      final after = clock.now().toUtc();
      expect(outcome, isA<OidcSignedIn>());
      final signedIn = outcome as OidcSignedIn;
      expect(signedIn.tokens.accessToken, 'access-1-value');
      expect(signedIn.tokens.refreshToken, 'refresh-1-value');
      expect(signedIn.tokens.idToken, isNotEmpty);
      expect(signedIn.claims['sub'], fakeSubject);
      expect(signedIn.claims['realm_access'], {
        'roles': ['admin'],
      });
      final expiresAt = signedIn.tokens.accessTokenExpiresAt;
      expect(expiresAt.isUtc, isTrue);
      expect(expiresAt.isBefore(before.add(const Duration(seconds: 120))), isFalse);
      expect(expiresAt.isAfter(after.add(const Duration(seconds: 120))), isFalse);
      await expectStoreEmpty();
    });

    test('OidcTokens masks every token in toString', () async {
      final outcome = await signIn(newClient()) as OidcSignedIn;

      final text = outcome.tokens.toString();
      expect(text, isNot(contains(outcome.tokens.accessToken)));
      expect(text, isNot(contains(outcome.tokens.idToken)));
      expect(text, isNot(contains(outcome.tokens.refreshToken!)));
    });

    test('the platform answering null is OidcSignInCancelled', () async {
      platform.authorization = FakeAuthorization.cancel;

      expect(await signIn(newClient()), isA<OidcSignInCancelled>());
      expect(provider.tokenRequests, isEmpty);
      await expectStoreEmpty();
    });

    test('an ID token with a wrong aud is failed', () async {
      provider.audience = 'someone-else';

      expect(await signIn(newClient()), _failed(OidcFailure.failed));
      await expectStoreEmpty();
    });

    test('an ID token with another nonce is failed', () async {
      provider.codeAnswer = () => provider.tokenAnswer(nonce: 'another-nonce');

      expect(await signIn(newClient()), _failed(OidcFailure.failed));
      expect(provider.tokenRequests, hasLength(1));
      await expectStoreEmpty();
    });

    test('the claims leave out the nonce, at_hash and c_hash of the ID token', () async {
      provider.hashClaims = true;

      final outcome = await signIn(newClient());

      expect(outcome, isA<OidcSignedIn>());
      final signedIn = outcome as OidcSignedIn;
      final idTokenClaims = JsonWebToken.unverified(signedIn.tokens.idToken).claims.toJson();
      expect(idTokenClaims.keys, containsAll(<String>['nonce', 'at_hash', 'c_hash']));
      expect(signedIn.claims.keys, isNot(anyOf(contains('nonce'), contains('at_hash'), contains('c_hash'))));
      expect(signedIn.claims['sub'], fakeSubject);
      expect(signedIn.claims['preferred_username'], 'person');
      expect(signedIn.claims.toString(), isNot(contains(idTokenClaims['nonce'] as String)));
    });

    test('an ID token with a bad signature is failed', () async {
      provider.signWithForeignKey = true;

      expect(await signIn(newClient()), _failed(OidcFailure.failed));
      await expectStoreEmpty();
    });

    test('discovery answering 500 is discovery', () async {
      provider.discoveryAnswer = () => http.Response('<html>down</html>', 500);

      expect(await signIn(newClient()), _failed(OidcFailure.discovery));
      expect(platform.authorizeRequests, isEmpty);
    });

    test('discovery unreachable is discovery', () async {
      provider.discoveryAnswer = () => throw http.ClientException('connection refused');

      expect(await signIn(newClient()), _failed(OidcFailure.discovery));
    });

    test('a failed discovery is fetched again by the next sign-in', () async {
      provider.discoveryAnswer = () => throw http.ClientException('connection refused');
      final client = newClient();
      expect(await signIn(client), _failed(OidcFailure.discovery));

      provider.discoveryAnswer = null;

      expect(await signIn(client), isA<OidcSignedIn>());
    });

    test('a manager whose discovery failed is disposed', () async {
      provider.discoveryAnswer = () => throw http.ClientException('connection refused');
      final managers = <AppOidcUserManager>[];

      expect(await signIn(newClient(onManagerCreated: managers.add)), _failed(OidcFailure.discovery));

      expect(managers.single.isDisposed, isTrue, reason: 'the failed manager was left running');
    });

    test('a Linux browser flow that times out is OidcSignInCancelled', () async {
      platform.authorization = FakeAuthorization.flowTimeout;

      expect(await signIn(newClient(platformKind: OidcPlatformKind.linux)), isA<OidcSignInCancelled>());
      expect(provider.tokenRequests, isEmpty);
      await expectStoreEmpty();
    });

    test('a token endpoint that times out after the Linux browser answered is discovery', () async {
      provider.codeAnswer = () => throw TimeoutException('no answer');

      expect(await signIn(newClient(platformKind: OidcPlatformKind.linux)), _failed(OidcFailure.discovery));
    });

    test('a timeout after a flow that timed out is still discovery', () async {
      final client = newClient(platformKind: OidcPlatformKind.linux);
      platform.authorization = FakeAuthorization.flowTimeout;
      expect(await signIn(client), isA<OidcSignInCancelled>());

      platform.authorization = FakeAuthorization.code;
      provider.codeAnswer = () => throw TimeoutException('no answer');

      expect(await signIn(client), _failed(OidcFailure.discovery));
    });

    test('a sign-in that fails before the browser after a flow that timed out is failed, not cancelled', () async {
      final writes = _BreakableKeyValue();
      final client = newClient(
        platformKind: OidcPlatformKind.linux,
        transactionStore: OidcTransactionStore(persistent: writes, tab: writes),
      );
      platform.authorization = FakeAuthorization.flowTimeout;
      expect(await signIn(client), isA<OidcSignInCancelled>());

      platform.authorization = FakeAuthorization.code;
      writes.failWrites = true;

      expect(await signIn(client), _failed(OidcFailure.failed));
      expect(platform.authorizeRequests, hasLength(1), reason: 'the second sign-in reached the browser');
    });

    test('discovery naming another issuer is discovery', () async {
      provider.discoveryIssuer = 'https://evil.test/realms/demo';

      expect(await signIn(newClient()), _failed(OidcFailure.discovery));
      expect(platform.authorizeRequests, isEmpty);
    });

    test('the JWKS answering 500 is discovery', () async {
      provider.jwksAnswer = () => http.Response('<html>down</html>', 500);

      expect(await signIn(newClient()), _failed(OidcFailure.discovery));
      await expectStoreEmpty();
    });

    test('the JWKS unreachable is discovery', () async {
      provider.jwksAnswer = () => throw http.ClientException('connection reset');

      expect(await signIn(newClient()), _failed(OidcFailure.discovery));
    });

    test('the token endpoint unreachable is discovery', () async {
      provider.codeAnswer = () => throw http.ClientException('connection reset');

      expect(await signIn(newClient()), _failed(OidcFailure.discovery));
      await expectStoreEmpty();
    });

    test('an error=access_denied redirect is failed', () async {
      platform.authorization = FakeAuthorization.accessDenied;

      expect(await signIn(newClient()), _failed(OidcFailure.failed));
      expect(provider.tokenRequests, isEmpty);
      await expectStoreEmpty();
    });

    test('a token endpoint invalid_grant is failed', () async {
      provider.codeAnswer = () => FakeProvider.errorAnswer('invalid_grant');

      expect(await signIn(newClient()), _failed(OidcFailure.failed));
      await expectStoreEmpty();
    });

    test('a token answer without an ID token is failed', () async {
      provider.codeAnswer = () => provider.tokenAnswer(idToken: false);

      expect(await signIn(newClient()), _failed(OidcFailure.failed));
    });

    test('a token answer with an empty access token is failed', () async {
      provider.codeAnswer = () => provider.tokenAnswer(nonce: provider.nonce, accessToken: '');

      expect(await signIn(newClient()), _failed(OidcFailure.failed));
    });

    test('a token answer without expires_in is failed', () async {
      provider.expiresIn = null;

      expect(await signIn(newClient()), _failed(OidcFailure.failed));
      await expectStoreEmpty();
    });

    test('the authorization URL carries prompt=login, S256 PKCE, a nonce and the audience', () async {
      await signIn(newClient(settings: settingsFor(provider, audience: 'https://api.example.test')));

      final query = platform.lastAuthorizeUri.queryParameters;
      expect(query['prompt'], 'login');
      expect(query['code_challenge_method'], 'S256');
      expect(query['code_challenge'], isNotEmpty);
      expect(query['nonce'], isNotEmpty);
      expect(query['audience'], 'https://api.example.test');
      expect(query['client_id'], fakeClientId);
      expect(query['redirect_uri'], 'com.example.flutterblocadvance:/oauth2redirect');
      expect(query, isNot(contains('id_token_hint')));
    });

    test('the authorization URL carries no prompt for omit and no audience when unset', () async {
      await signIn(newClient(settings: settingsFor(provider, prompt: OidcPrompt.omit)));

      final query = platform.lastAuthorizeUri.queryParameters;
      expect(query, isNot(contains('prompt')));
      expect(query, isNot(contains('audience')));
    });

    test('no request ever carries client_secret', () async {
      final client = newClient();
      final signedIn = await signIn(client) as OidcSignedIn;
      await client.refresh(
        refreshToken: signedIn.tokens.refreshToken!,
        idToken: signedIn.tokens.idToken,
        accessToken: signedIn.tokens.accessToken,
        accessTokenExpiresAt: signedIn.tokens.accessTokenExpiresAt,
      );

      expect(provider.tokenRequests, hasLength(2));
      for (final request in provider.requests) {
        expect(request.url.queryParameters, isNot(contains('client_secret')));
        expect(request.body, isNot(contains('client_secret')));
        expect(request.headers.keys.map((key) => key.toLowerCase()), isNot(contains('authorization')));
      }
      expect(platform.lastAuthorizeUri.queryParameters, isNot(contains('client_secret')));
    });

    test('the code exchange sends the PKCE verifier and a public client id', () async {
      await signIn(newClient());

      final form = FakeProvider.form(provider.tokenRequests.single);
      expect(form['grant_type'], 'authorization_code');
      expect(form['client_id'], fakeClientId);
      expect(form['code_verifier'], isNotEmpty);
    });

    test('Linux opens the browser through the given launcher and shows the escaped message', () async {
      await signIn(newClient(platformKind: OidcPlatformKind.linux));

      final options = platform.authorizeOptions.single;
      for (final native in [options.linux, options.windows]) {
        expect(native.flowTimeoutSeconds, 300);
        expect(native.launchUrl, isNotNull);
        expect(native.successfulPageResponse, contains('Signed in. You can close this tab &amp; go back to &lt;the'));
        expect(native.successfulPageResponse, isNot(contains('<the app>')));
      }
      final target = Uri.parse('https://idp.test/auth');
      expect(await options.linux.launchUrl!(target), isTrue);
      expect(launchedUrls, [target]);
      expect(platform.lastAuthorizeUri.queryParameters['redirect_uri'], 'http://127.0.0.1:0/oauth2redirect');
    });

    test('the platform options keep the Custom Tab, the shared Apple session and the same-tab web flow', () async {
      await signIn(newClient());

      final options = platform.authorizeOptions.single;
      expect(options.android.useAuthTab, OidcAuthTabMode.never);
      expect(options.ios.prefersEphemeralWebBrowserSession, isFalse);
      expect(options.macos.prefersEphemeralWebBrowserSession, isFalse);
      expect(options.web.navigationMode, OidcPlatformSpecificOptions_Web_NavigationMode.samePage);
    });
  });

  group('web', () {
    test('signIn returns OidcSignInNavigatedAway and leaves the state and the verifier in the store', () async {
      platform.authorization = FakeAuthorization.navigateAway;

      final outcome = await signIn(newClient(platformKind: OidcPlatformKind.web));

      expect(outcome, isA<OidcSignInNavigatedAway>());
      expect(await store.getAllKeys(OidcStoreNamespace.state), hasLength(1));
      expect(
        await store.getAllKeys(OidcStoreNamespace.secureTokens),
        contains(startsWith('code_verifier.')),
        reason: 'redirect.html and the reloaded tab need the state and the verifier',
      );
      expect(store.hasAbandonedSignIn(), isTrue);
    });

    test('signIn watches for a back-forward cache restore once, before the tab leaves', () async {
      platform.authorization = FakeAuthorization.navigateAway;
      final authorizeRequestsWhenWatched = <int>[];
      final client = newClient(
        platformKind: OidcPlatformKind.web,
        reloadOnPageRestore: () => authorizeRequestsWhenWatched.add(platform.authorizeRequests.length),
      );

      await signIn(client);
      await signIn(client);

      expect(authorizeRequestsWhenWatched, [0], reason: 'one pageshow listener, registered before the navigation');
    });

    test('a native sign-in does not watch for a back-forward cache restore', () async {
      await signIn(newClient(reloadOnPageRestore: () => fail('a native sign-in has no page to restore')));
    });

    test('signIn sends the app entry URI with the return path and no id_token_hint', () async {
      platform.authorization = FakeAuthorization.navigateAway;

      await signIn(newClient(platformKind: OidcPlatformKind.web));

      final request = platform.authorizeRequests.single;
      expect(request.redirectUri, Uri.parse('http://localhost:8081/redirect.html'));
      expect(request.idTokenHint, isNull);
      final stateData = await store.getStateData(request.state!);
      expect(jsonDecode(stateData!)['original_uri'], 'http://localhost:8081/#/users');
    });

    test('completePendingSignIn returns null and reads nothing but the store when nothing is pending', () async {
      expect(await newClient(platformKind: OidcPlatformKind.web).completePendingSignIn(), isNull);
      expect(provider.requests, isEmpty);
    });

    test('an abandoned transaction is OidcSignInCancelled, with no request, and the store is emptied', () async {
      await store.setStateCodeVerifier(state: 'state-1', codeVerifier: 'verifier-1');
      await store.setStateData(state: 'state-1', stateData: '{"id":"state-1"}');
      await store.setCurrentNonce('nonce-1');

      final outcome = await newClient(platformKind: OidcPlatformKind.web).completePendingSignIn();

      expect(outcome, isA<OidcSignInCancelled>());
      expect(provider.requests, isEmpty);
      await expectStoreEmpty();
    });

    /// Starts a web sign-in, then stores the provider's redirect the way redirect.html does, and returns a new client
    /// over a new store on the same storage, as the reloaded tab builds them.
    Future<OidcClient> reloadAfterRedirect(
      Map<String, String> Function(OidcAuthorizeRequest request) parameters,
    ) async {
      platform.authorization = FakeAuthorization.navigateAway;
      await signIn(newClient(platformKind: OidcPlatformKind.web));
      final request = platform.authorizeRequests.single;
      await store.setStateResponseData(
        state: request.state!,
        stateData: request.redirectUri.replace(queryParameters: parameters(request)).toString(),
      );
      provider.requests.clear();
      store = OidcTransactionStore(persistent: persistent, tab: tab);
      return newClient(platformKind: OidcPlatformKind.web);
    }

    test('completePendingSignIn completes the same-tab sign-in from the store', () async {
      final reloaded = await reloadAfterRedirect((request) => {'code': 'code-value', 'state': request.state!});

      final outcome = await reloaded.completePendingSignIn();

      expect(outcome, isA<OidcSignedIn>());
      expect((outcome as OidcSignedIn).tokens.accessToken, 'access-1-value');
      expect(outcome.claims['sub'], fakeSubject);
      await expectStoreEmpty();
    });

    test('a provider error response is failed and cleared, so the next sign-in starts clean', () async {
      final reloaded = await reloadAfterRedirect((request) => {'error': 'access_denied', 'state': request.state!});

      expect(await reloaded.completePendingSignIn(), _failed(OidcFailure.failed));
      await expectStoreEmpty();
      expect(await reloaded.completePendingSignIn(), isNull);
    });

    test('a completion whose ID token fails a claim check is failed and cleared', () async {
      final reloaded = await reloadAfterRedirect((request) => {'code': 'code-value', 'state': request.state!});
      provider.audience = 'someone-else';

      expect(await reloaded.completePendingSignIn(), _failed(OidcFailure.failed));
      await expectStoreEmpty();
    });

    test('a completion whose code exchange is refused is failed and cleared', () async {
      final reloaded = await reloadAfterRedirect((request) => {'code': 'code-value', 'state': request.state!});
      provider.codeAnswer = () => FakeProvider.errorAnswer('invalid_grant');

      expect(await reloaded.completePendingSignIn(), _failed(OidcFailure.failed));
      await expectStoreEmpty();
    });

    test('a completion whose discovery is unreachable is discovery and cleared', () async {
      final reloaded = await reloadAfterRedirect((request) => {'code': 'code-value', 'state': request.state!});
      provider.discoveryAnswer = () => throw http.ClientException('connection refused');

      expect(await reloaded.completePendingSignIn(), _failed(OidcFailure.discovery));
      await expectStoreEmpty();
    });

    test('a completion whose code exchange is unreachable is discovery and cleared', () async {
      final reloaded = await reloadAfterRedirect((request) => {'code': 'code-value', 'state': request.state!});
      provider.codeAnswer = () => throw http.ClientException('connection reset');

      expect(await reloaded.completePendingSignIn(), _failed(OidcFailure.discovery));
      await expectStoreEmpty();
    });

    test(
      'a malformed response index escapes the completion, which clears the store so the next sign-in starts',
      () async {
        final reloaded = await reloadAfterRedirect((request) => {'code': 'code-value', 'state': request.state!});
        persistent.write('oidc.keys.response.state', '["state-secret-1",');

        await expectLater(reloaded.completePendingSignIn(), throwsFormatException);

        expect(persistent.read('oidc.keys.response.state'), isNull);
        await expectStoreEmpty();
        expect(provider.requests, isEmpty);
        expect(await reloaded.completePendingSignIn(), isNull);
        expect(await signIn(reloaded), isA<OidcSignInNavigatedAway>());
      },
    );
  });

  group('Android', () {
    testWidgets('resuming the app while a sign-in is pending cancels it', (tester) async {
      platform.authorization = FakeAuthorization.pending;
      var cancels = 0;
      final client = newClient(
        platformKind: OidcPlatformKind.android,
        cancelAndroidFlow: () async {
          cancels++;
          platform.completePending();
        },
      );

      final outcome = await tester.runAsync(() async {
        final result = signIn(client);
        while (!platform.hasPending) {
          await Future<void>.delayed(Duration.zero);
        }
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        return result;
      });

      expect(outcome, isA<OidcSignInCancelled>());
      expect(cancels, 1);
      await tester.runAsync(expectStoreEmpty);
    });

    testWidgets('resuming the app after the sign-in ended cancels nothing', (tester) async {
      var cancels = 0;
      final client = newClient(platformKind: OidcPlatformKind.android, cancelAndroidFlow: () async => cancels++);

      final outcome = await tester.runAsync(() => signIn(client));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      expect(outcome, isA<OidcSignedIn>());
      expect(cancels, 0);
    });

    testWidgets('resuming the app while a provider logout is pending cancels it', (tester) async {
      platform.endSession = FakeEndSession.pending;
      final client = newClient(
        platformKind: OidcPlatformKind.android,
        cancelAndroidFlow: () async {
          platform.completePending();
        },
      );

      final outcome = await tester.runAsync(() async {
        final result = client.endProviderSession(idTokenHint: 'id-token-value');
        while (!platform.hasPending) {
          await Future<void>.delayed(Duration.zero);
        }
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        return result;
      });

      expect(outcome, isA<ProviderLogoutFailed>());
    });
  });

  group('refresh', () {
    Future<TokenRotationResult> refresh(OidcClient client, {String? idToken}) => client.refresh(
      refreshToken: 'refresh-old-value',
      idToken: idToken ?? provider.signIdToken(),
      accessToken: 'access-old-value',
      accessTokenExpiresAt: clock.now().toUtc().subtract(const Duration(seconds: 5)),
    );

    test('a new ID token gives TokensRotated with a new expiry and oidcIdToken', () async {
      provider.expiresIn = 60;
      final before = clock.now().toUtc();

      final result = await refresh(newClient());

      expect(result, isA<TokensRotated>());
      final rotated = result as TokensRotated;
      expect(rotated.accessToken, 'access-1-value');
      expect(rotated.refreshToken, 'refresh-1-value');
      expect(rotated.oidcIdToken, isNotEmpty);
      expect(rotated.accessTokenExpiresAt!.isBefore(before.add(const Duration(seconds: 60))), isFalse);
      final form = FakeProvider.form(provider.tokenRequests.single);
      expect(form['grant_type'], 'refresh_token');
      expect(form['refresh_token'], 'refresh-old-value');
      expect(form['client_id'], fakeClientId);
      await expectStoreEmpty();
    });

    test('an answer without an ID token keeps the old one', () async {
      provider.refreshReturnsIdToken = false;

      final result = await refresh(newClient());

      expect(result, isA<TokensRotated>());
      expect((result as TokensRotated).oidcIdToken, isNull);
      expect(result.accessToken, 'access-1-value');
    });

    test('an already expired stored ID token still refreshes', () async {
      provider.refreshReturnsIdToken = false;
      final expired = provider.signIdToken(ttl: const Duration(minutes: -10));

      final result = await refresh(newClient(), idToken: expired);

      expect(result, isA<TokensRotated>());
      expect(provider.tokenRequests, hasLength(1));
    });

    test('an already expired stored ID token refreshes to a new one', () async {
      final expired = provider.signIdToken(ttl: const Duration(minutes: -10));

      final result = await refresh(newClient(), idToken: expired);

      expect(result, isA<TokensRotated>());
      expect((result as TokensRotated).oidcIdToken, isNot(expired));
    });

    test('an answer without expires_in gives no expiry', () async {
      provider.expiresIn = null;

      final result = await refresh(newClient());

      expect(result, isA<TokensRotated>());
      expect((result as TokensRotated).accessTokenExpiresAt, isNull);
    });

    test('an answer with an empty access token is RotationRefused', () async {
      provider.refreshAnswer = () => provider.tokenAnswer(accessToken: '');

      expect(await refresh(newClient()), isA<RotationRefused>());
    });

    test('invalid_grant is RotationRefused', () async {
      provider.refreshAnswer = () => FakeProvider.errorAnswer('invalid_grant');

      expect(await refresh(newClient()), isA<RotationRefused>());
      await expectStoreEmpty();
    });

    test('invalid_client is RotationRefused', () async {
      provider.refreshAnswer = () => FakeProvider.errorAnswer('invalid_client', status: 401);

      expect(await refresh(newClient()), isA<RotationRefused>());
    });

    test('a transport error is RotationUnavailable', () async {
      provider.refreshAnswer = () => throw http.ClientException('connection reset');

      expect(await refresh(newClient()), isA<RotationUnavailable>());
      await expectStoreEmpty();
    });

    for (final error in ['server_error', 'temporarily_unavailable']) {
      test('$error is RotationUnavailable', () async {
        provider.refreshAnswer = () => FakeProvider.errorAnswer(error, status: 503);

        expect(await refresh(newClient()), isA<RotationUnavailable>());
      });
    }

    test('a 502 with an HTML body is RotationUnavailable', () async {
      provider.refreshAnswer = () => http.Response('<html>Bad gateway</html>', 502);

      expect(await refresh(newClient()), isA<RotationUnavailable>());
    });

    test('a 400 with a body that is not JSON is RotationRefused', () async {
      provider.refreshAnswer = () => http.Response('bad request', 400);

      expect(await refresh(newClient()), isA<RotationRefused>());
    });

    test('a refreshed ID token with a wrong aud is RotationRefused', () async {
      final stored = provider.signIdToken();
      provider.audience = 'someone-else';

      expect(await refresh(newClient(), idToken: stored), isA<RotationRefused>());
    });

    test('a refreshed ID token with a bad signature is RotationRefused', () async {
      final stored = provider.signIdToken();
      provider.signWithForeignKey = true;

      expect(await refresh(newClient(), idToken: stored), isA<RotationRefused>());
    });

    test('a stored ID token that does not parse is RotationRefused, with no request', () async {
      expect(await refresh(newClient(), idToken: 'not-a-jwt'), isA<RotationRefused>());
      expect(provider.tokenRequests, isEmpty);
    });

    // The token endpoint has already answered, so the old refresh token is spent: the new tokens are kept, and the
    // new ID token, which could not be checked, is left out so the stored one stays.
    void expectRotatedWithoutIdToken(TokenRotationResult result) {
      expect(result, isA<TokensRotated>());
      final rotated = result as TokensRotated;
      expect(rotated.accessToken, 'access-1-value');
      expect(rotated.refreshToken, 'refresh-1-value');
      expect(rotated.oidcIdToken, isNull);
      expect(rotated.accessTokenExpiresAt, isNotNull);
      expect(provider.tokenRequests, hasLength(1));
    }

    test(
      'the JWKS answering 500 with an HTML body during a refresh keeps the new tokens and the old ID token',
      () async {
        provider.jwksAnswer = () => http.Response('<html>down</html>', 500);

        expectRotatedWithoutIdToken(await refresh(newClient()));
        await expectStoreEmpty();
      },
    );

    test(
      'the JWKS answering 503 with a JSON body during a refresh keeps the new tokens and the old ID token',
      () async {
        provider.jwksAnswer = () =>
            http.Response('{"error":"temporarily_unavailable"}', 503, headers: {'content-type': 'application/json'});

        expectRotatedWithoutIdToken(await refresh(newClient()));
        await expectStoreEmpty();
      },
    );

    test('the JWKS unreachable during a refresh keeps the new tokens and the old ID token', () async {
      provider.jwksAnswer = () => throw http.ClientException('connection reset');

      expectRotatedWithoutIdToken(await refresh(newClient()));
      await expectStoreEmpty();
    });

    test('a token endpoint 429 is RotationUnavailable, whatever its error code', () async {
      provider.refreshAnswer = () => FakeProvider.errorAnswer('invalid_request', status: 429);

      expect(await refresh(newClient()), isA<RotationUnavailable>());
    });

    test('a token endpoint 500 with an unknown error code is RotationUnavailable', () async {
      provider.refreshAnswer = () => FakeProvider.errorAnswer('database_on_fire', status: 500);

      expect(await refresh(newClient()), isA<RotationUnavailable>());
    });

    test('discovery unreachable during a refresh gives RotationUnavailable', () async {
      provider.discoveryAnswer = () => throw http.ClientException('connection refused');

      expect(await refresh(newClient()), isA<RotationUnavailable>());
      expect(provider.tokenRequests, isEmpty);
    });

    test('discovery 500 during a refresh gives RotationUnavailable', () async {
      provider.discoveryAnswer = () => http.Response('<html>down</html>', 500);

      expect(await refresh(newClient()), isA<RotationUnavailable>());
      expect(provider.tokenRequests, isEmpty);
    });

    test('an expired session is refreshed with exactly one token request', () async {
      final result = await refresh(newClient());

      expect(result, isA<TokensRotated>());
      expect(provider.tokenRequests, hasLength(1), reason: 'a package timer refreshed the adopted session as well');
    });

    test('a sign-in after a refresh sends no id_token_hint', () async {
      final client = newClient();
      await refresh(client);

      await signIn(client);

      expect(platform.lastAuthorizeUri.queryParameters, isNot(contains('id_token_hint')));
    });
  });

  test(
    'no background refresh: an access token that has expired at the sign-in is not refreshed by the package',
    () async {
      // Real time, not fake time: jose_plus verifies the ID token signature on a path that never completes under
      // fake_async, so a sign-in in fake time never ends and a test that advances the clock past expires_in cannot
      // run. A token that has expired when it arrives makes the package's expired timer fire at once instead, which
      // the client forgetting its user after the sign-in cannot hide.
      // The package's expired timer fires at once for such a token and refreshes it, unless the manager arms no timer.
      provider.expiresIn = 0;
      // A refused refresh ends the package's refresh loop, which would otherwise never stop for a 0 second token.
      provider.refreshAnswer = () => FakeProvider.errorAnswer('invalid_grant');

      expect(await newClient().signIn(browserDoneMessage: _doneMessage), isA<OidcSignedIn>());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(provider.tokenRequests, hasLength(1), reason: 'a package timer refreshed the token during the sign-in');
    },
  );

  group('one operation at a time', () {
    test('a sign-in started during a refresh runs after it, and its ID token signature is still checked', () async {
      final refreshAnswer = Completer<http.Response>();
      provider.refreshAnswer = () => refreshAnswer.future;
      final client = newClient();
      final refreshing = client.refresh(
        refreshToken: 'refresh-old-value',
        idToken: provider.signIdToken(),
        accessToken: 'access-old-value',
        accessTokenExpiresAt: clock.now().toUtc(),
      );
      while (provider.tokenRequests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      provider.signWithForeignKey = true;

      final signingIn = signIn(client);
      for (var turn = 0; turn < 20; turn++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(platform.authorizeRequests, isEmpty, reason: 'the sign-in started while the refresh was in flight');
      refreshAnswer.complete(provider.tokenAnswer(idToken: false));
      expect(await refreshing, isA<TokensRotated>());
      expect(await signingIn, _failed(OidcFailure.failed));
      expect(platform.authorizeRequests, hasLength(1));
      await expectStoreEmpty();
    });

    test('a refresh started during a sign-in runs after it', () async {
      platform.authorization = FakeAuthorization.pending;
      final client = newClient();
      final signingIn = signIn(client);
      while (!platform.hasPending) {
        await Future<void>.delayed(Duration.zero);
      }

      final refreshing = client.refresh(
        refreshToken: 'refresh-old-value',
        idToken: provider.signIdToken(),
        accessToken: 'access-old-value',
        accessTokenExpiresAt: clock.now().toUtc(),
      );
      for (var turn = 0; turn < 20; turn++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(provider.tokenRequests, isEmpty, reason: 'the refresh started while the sign-in was pending');
      platform.completePending();
      expect(await signingIn, isA<OidcSignInCancelled>());
      expect(await refreshing, isA<TokensRotated>());
    });

    test('an operation that throws does not stop the next one', () async {
      // A web sign-in that answers a user instead of leaving the page throws.
      final client = newClient(platformKind: OidcPlatformKind.web);

      await expectLater(signIn(client), throwsStateError);

      expect(await client.endProviderSession(), isA<ProviderLogoutNavigatedAway>());
    });
  });

  test('a web completion disposes the manager it replaces', () async {
    final managers = <AppOidcUserManager>[];
    platform.authorization = FakeAuthorization.navigateAway;
    final client = newClient(platformKind: OidcPlatformKind.web, onManagerCreated: managers.add);
    await signIn(client);
    final request = platform.authorizeRequests.single;
    await store.setStateResponseData(
      state: request.state!,
      stateData: request.redirectUri
          .replace(queryParameters: {'code': 'code-value', 'state': request.state!})
          .toString(),
    );

    expect(await client.completePendingSignIn(), isA<OidcSignedIn>());

    expect(managers, hasLength(2));
    expect(managers.first.isDisposed, isTrue, reason: 'the replaced manager was left running');
    expect(managers.last.isDisposed, isFalse);
  });

  group('endProviderSession', () {
    test('with a hint, the end-session URL carries client_id, post_logout_redirect_uri and id_token_hint', () async {
      final outcome = await newClient().endProviderSession(idTokenHint: 'id-token-value');

      expect(outcome, isA<ProviderSessionEnded>());
      final uri = platform.lastEndSessionUri;
      expect(uri.replace(query: ''), provider.logoutUri.replace(query: ''));
      expect(uri.queryParameters, {
        'client_id': fakeClientId,
        'post_logout_redirect_uri': 'com.example.flutterblocadvance:/oauth2redirect',
        'id_token_hint': 'id-token-value',
      });
    });

    test('without a hint, the URL has no id_token_hint, even after a sign-in', () async {
      final client = newClient();
      await signIn(client);

      await client.endProviderSession();

      expect(platform.lastEndSessionUri.queryParameters, isNot(contains('id_token_hint')));
      expect(platform.lastEndSessionUri.queryParameters, contains('client_id'));
    });

    test('an Auth0 issuer with no end_session_endpoint uses /v2/logout with returnTo', () async {
      final auth0 = FakeProvider(issuer: 'https://tenant.eu.auth0.com/', endSessionEndpoint: false);
      final client = newClient(at: auth0, settings: settingsFor(auth0));

      final outcome = await client.endProviderSession(idTokenHint: 'id-token-value');

      expect(outcome, isA<ProviderSessionEnded>());
      final uri = platform.lastEndSessionUri;
      expect(uri.replace(query: ''), Uri.parse('https://tenant.eu.auth0.com/v2/logout?'));
      expect(uri.queryParameters['client_id'], fakeClientId);
      expect(uri.queryParameters['returnTo'], 'com.example.flutterblocadvance:/oauth2redirect');
      expect(uri.queryParameters['post_logout_redirect_uri'], 'com.example.flutterblocadvance:/oauth2redirect');
    });

    test('the auth0.com host itself also uses /v2/logout', () async {
      final auth0 = FakeProvider(issuer: 'https://auth0.com/', endSessionEndpoint: false);

      final outcome = await newClient(at: auth0, settings: settingsFor(auth0)).endProviderSession();

      expect(outcome, isA<ProviderSessionEnded>());
      expect(platform.lastEndSessionUri.path, '/v2/logout');
    });

    test('a host that only contains auth0.com is not Auth0', () async {
      final other = FakeProvider(issuer: 'https://notauth0.com/', endSessionEndpoint: false);

      expect(await newClient(at: other, settings: settingsFor(other)).endProviderSession(), isA<NoProviderLogout>());
    });

    test('no endpoint gives NoProviderLogout and opens nothing', () async {
      final google = FakeProvider(issuer: 'https://accounts.idp.test', endSessionEndpoint: false);

      final outcome = await newClient(at: google, settings: settingsFor(google)).endProviderSession();

      expect(outcome, isA<NoProviderLogout>());
      expect(platform.endSessionRequests, isEmpty);
    });

    test('a platform OidcException gives ProviderLogoutFailed', () async {
      platform.endSession = FakeEndSession.fails;

      expect(await newClient().endProviderSession(idTokenHint: 'id-token-value'), isA<ProviderLogoutFailed>());
    });

    test('a native null answer, the user closing the browser, gives ProviderLogoutFailed', () async {
      platform.endSession = FakeEndSession.nullAnswer;

      expect(await newClient().endProviderSession(), isA<ProviderLogoutFailed>());
    });

    test('discovery unreachable gives ProviderLogoutFailed', () async {
      provider.discoveryAnswer = () => throw http.ClientException('connection refused');

      expect(await newClient().endProviderSession(), isA<ProviderLogoutFailed>());
    });

    test('on web, the same-tab navigation gives ProviderLogoutNavigatedAway', () async {
      platform.endSession = FakeEndSession.nullAnswer;

      final outcome = await newClient(platformKind: OidcPlatformKind.web).endProviderSession();

      expect(outcome, isA<ProviderLogoutNavigatedAway>());
      expect(platform.lastEndSessionUri.queryParameters['post_logout_redirect_uri'], 'http://localhost:8081/');
    });

    test('Linux logs out through the given launcher with the loopback logout URI', () async {
      await newClient(platformKind: OidcPlatformKind.linux).endProviderSession();

      final options = platform.endSessionOptions.single;
      expect(options.linux.launchUrl, isNotNull);
      expect(options.linux.flowTimeoutSeconds, 300);
      expect(platform.lastEndSessionUri.queryParameters['post_logout_redirect_uri'], 'http://127.0.0.1:0/logout');
    });
  });
}

Matcher _failed(OidcFailure failure) =>
    isA<OidcSignInFailed>().having((outcome) => outcome.failure, 'failure', failure);

/// A [MemoryKeyValue] whose writes throw while [failWrites] is set, so a sign-in fails before its browser step.
final class _BreakableKeyValue implements OidcKeyValue {
  final _values = MemoryKeyValue();
  bool failWrites = false;

  @override
  String? read(String key) => _values.read(key);

  @override
  void write(String key, String value) {
    if (failWrites) throw StateError('The store is not writable');
    _values.write(key, value);
  }

  @override
  void delete(String key) => _values.delete(key);

  @override
  Iterable<String> get keys => _values.keys;
}
