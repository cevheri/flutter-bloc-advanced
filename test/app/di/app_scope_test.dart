@Tags(['widget'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/di/app_scope.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/features/lifecycle/data/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

/// Production behavior (no mock interceptor, token expiry enforced) with a valid base URL instead of the template
/// placeholder in [AppConfig.prod].
const _prodConfig = AppConfig(
  environment: Environment.prod,
  apiBaseUrl: 'https://api.example.test',
  certificatePins: <String>[],
  idleTimeout: null,
);

/// A JWT whose `exp` lies far in the future, so a production [SessionCubit] restores it as authenticated.
String _unexpiredJwt() => _jwt(exp: 4102444800);

/// A JWT whose `exp` has passed, so a production [SessionCubit] restores it as signed out but leaves it stored.
String _expiredJwt() => _jwt(exp: 946684800);

String _jwt({required int exp, String sub = 'admin'}) {
  String part(Map<String, Object> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': sub, 'exp': exp})}.signature';
}

/// Answers every request with 401, like a server that rejects the stored token.
class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{}', 401);

  @override
  void close({bool force = false}) {}
}

/// Answers each request from [_routes] by method and path, and records it with its Authorization header. Like a
/// Spring Security resource server, it answers 401 to a request that carries an expired token before it looks at the
/// endpoint, public ones included.
class _ServerAdapter implements HttpClientAdapter {
  _ServerAdapter(this._routes);

  final Map<String, (int, Object)> _routes;
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final route = '${options.method} ${options.path}';
    final authorization = options.headers['Authorization'] as String?;
    requests.add('$route $authorization');
    if (authorization == 'Bearer ${_expiredJwt()}') return ResponseBody.fromString('invalid_token', 401);
    final (statusCode, body) = _routes[route] ?? (throw StateError('No route for $route'));
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Counts the clears that reach it.
class _CountingSessionRepository implements IAuthSessionRepository {
  int clears = 0;

  @override
  Future<Result<void>> persist(AuthSession session) async => const Success(null);

  @override
  Future<Result<void>> clear() async {
    clears++;
    return const Success(null);
  }
}

/// The test config with [sessionRepository] in place of the one AppDependencies creates.
class _SessionRepositoryDependencies extends AppDependencies {
  const _SessionRepositoryDependencies(this.sessionRepository) : super(appConfig: const AppConfig.test());

  final IAuthSessionRepository sessionRepository;

  @override
  IAuthSessionRepository createAuthSessionRepository(ISecureStorage secureStorage) => sessionRepository;
}

/// The production dependencies, counting how often the client reports a 401 that a token refresh could not fix.
class _CountingDependencies extends AppDependencies {
  _CountingDependencies() : super(appConfig: _prodConfig);

  int sessionExpiredCalls = 0;

  @override
  ApiClient createApiClient(ISecureStorage secureStorage, {required OnSessionExpired onSessionExpired}) =>
      super.createApiClient(
        secureStorage,
        onSessionExpired: () {
          sessionExpiredCalls++;
          onSessionExpired();
        },
      );
}

/// Pumps [AppScope] over an expired stored session, the state a production launch leaves the login page in: restore()
/// reports the expired JWT as signed out but leaves it and the refresh token stored. Returns a context below the scope.
Future<BuildContext> _pumpExpiredSession(WidgetTester tester, AppDependencies dependencies) async {
  await FlutterSecureStorageAdapter().write(SecureStorageKeys.jwtToken.key, _expiredJwt());
  await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'stored-refresh-token');
  late BuildContext scope;
  await tester.pumpWidget(
    AppScope(
      dependencies: dependencies,
      defaultLocale: const Locale('en'),
      child: Builder(
        builder: (context) {
          scope = context;
          return const SizedBox();
        },
      ),
    ),
  );
  final session = scope.read<SessionCubit>();
  await tester.pumpAndSettle();
  expect(session.state, const SessionUnauthenticated(reason: SessionExpiredReason.expired));
  return scope;
}

/// Answers like the server while a token refresh races the end of the session: a request with [staleJwt] gets 401, the
/// refresh waits for [releaseRefresh] and then rotates the tokens to [freshJwt], and a request with [freshJwt] gets the
/// account. Records each request with its Authorization header.
class _RefreshRaceServer implements HttpClientAdapter {
  _RefreshRaceServer({required this.staleJwt, required this.freshJwt});

  final String staleJwt;
  final String freshJwt;
  final requests = <String>[];
  final refreshReceived = Completer<void>();
  final releaseRefresh = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final route = '${options.method} ${options.path}';
    final authorization = switch (options.headers['Authorization']) {
      final String header when header == 'Bearer $staleJwt' => 'Bearer stale',
      final String header when header == 'Bearer $freshJwt' => 'Bearer fresh',
      final other => '$other',
    };
    requests.add('$route $authorization');
    ResponseBody json(int statusCode, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
    if (route == 'POST /api/token/refresh') {
      refreshReceived.complete();
      await releaseRefresh.future;
      return json(200, {'id_token': freshJwt, 'refresh_token': 'rotated-refresh-token'});
    }
    if (authorization == 'Bearer fresh') {
      return json(200, {
        'id': 'user-1',
        'login': 'admin',
        'authorities': ['ROLE_ADMIN'],
      });
    }
    return json(401, {'title': 'Unauthorized'});
  }

  @override
  void close({bool force = false}) {}
}

/// Answers like the server while a request of one user is on its way and that user signs out and another signs in:
/// the account save sent with [signedOutJwt] waits for [releaseSave] and is then rejected with 401, the sign-in answers
/// with [signedInJwt], and every request with [signedInJwt] succeeds. Records each request with its Authorization
/// header.
class _SignInRaceServer implements HttpClientAdapter {
  _SignInRaceServer({required this.signedOutJwt, required this.signedInJwt});

  final String signedOutJwt;
  final String signedInJwt;
  final requests = <String>[];
  final saveReceived = Completer<void>();
  final releaseSave = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final route = '${options.method} ${options.path}';
    final authorization = switch (options.headers['Authorization']) {
      final String header when header == 'Bearer $signedOutJwt' => 'Bearer signed-out-user',
      final String header when header == 'Bearer $signedInJwt' => 'Bearer signed-in-user',
      final other => '$other',
    };
    requests.add('$route $authorization');
    ResponseBody json(int statusCode, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
    switch ((route, authorization)) {
      case ('POST /authenticate', 'null'):
        return json(200, {'id_token': signedInJwt, 'refresh_token': 'signed-in-refresh-token'});
      case ('POST /account', 'Bearer signed-out-user'):
        saveReceived.complete();
        await releaseSave.future;
        return json(401, {'title': 'Unauthorized'});
      case (_, 'Bearer signed-in-user'):
        return json(200, {
          'id': 'user-2',
          'login': 'user-two',
          'authorities': ['ROLE_USER'],
        });
    }
    return json(401, {'title': 'Unauthorized'});
  }

  @override
  void close({bool force = false}) {}
}

/// Pumps until [done] holds, so a test can run a request, a token refresh and the end of the session in a fixed order.
Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 50 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(done(), isTrue);
}

final _oidcSettings = OidcSettings(issuer: Uri.parse('https://id.example.com/realms/demo'), clientId: 'app');

/// Signs in with [outcome], as a provider would after the user signed in on its page.
class _FakeOidcClient implements IOidcClient {
  _FakeOidcClient(this.outcome);

  final OidcSignInOutcome outcome;

  @override
  Future<OidcSignInOutcome> signIn({String? webReturnPath, required String browserDoneMessage}) async => outcome;

  @override
  Future<OidcSignInOutcome?> completePendingSignIn() async => null;

  @override
  Future<TokenRotationResult> refresh({
    required String refreshToken,
    required String idToken,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) => throw UnimplementedError('these tests never refresh');

  @override
  Future<OidcLogoutOutcome> endProviderSession({String? idTokenHint}) =>
      throw UnimplementedError('these tests never log out');
}

/// The test config in [authMode], counting the OIDC clients it creates; each one is [client].
class _OidcClientDependencies extends AppDependencies {
  _OidcClientDependencies({required super.authMode, required this.client}) : super(appConfig: const AppConfig.test());

  final IOidcClient client;
  int oidcClientsCreated = 0;

  @override
  IOidcClient createOidcClient(OidcSettings settings) {
    oidcClientsCreated++;
    return client;
  }
}

/// Pumps [AppScope] over [dependencies] and returns a context below it.
Future<BuildContext> _pumpScope(WidgetTester tester, AppDependencies dependencies) async {
  late BuildContext scope;
  await tester.pumpWidget(
    AppScope(
      dependencies: dependencies,
      defaultLocale: const Locale('en'),
      child: Builder(
        builder: (context) {
          scope = context;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return scope;
}

/// The server's answer to a refresh, which a sign-in must never ask for.
final _refreshRoute = <String, (int, Object)>{
  'POST /api/token/refresh': (200, {'id_token': _unexpiredJwt(), 'refresh_token': 'rotated-refresh-token'}),
};

void main() {
  group('AppScope', () {
    testWidgets('ends the session and clears the stored session when a 401 cannot be refreshed', (tester) async {
      // A production config sends requests to the adapter instead of the mock assets. The adapter rejects the
      // refresh request too, so the stored refresh token cannot renew the session.
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.jwtToken.key, _unexpiredJwt());
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'rejected-refresh-token');
      await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN']);
      late BuildContext scope;
      await tester.pumpWidget(
        AppScope(
          dependencies: const AppDependencies(appConfig: _prodConfig),
          defaultLocale: const Locale('en'),
          child: Builder(
            builder: (context) {
              scope = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final session = scope.read<SessionCubit>();
      await tester.pumpAndSettle();
      expect(session.state, isA<SessionAuthenticated>());

      final apiClient = scope.read<ApiClient>();
      apiClient.instance.httpClientAdapter = _UnauthorizedAdapter();
      // Dio runs each interceptor step on a timer, so the request, the refresh and the wipe of the stored session run
      // while fake time moves, and all of them have finished when the pump returns.
      final request = expectLater(apiClient.get('/api/account'), throwsA(isA<UnauthorizedException>()));
      await tester.pump(Duration.zero);
      await request;

      expect(session.state, const SessionUnauthenticated(reason: SessionExpiredReason.expired));
      // A relaunch restores the session from secure storage, as AppScope does on launch.
      final relaunched = SessionCubit(secureStorage: FlutterSecureStorageAdapter(), appConfig: _prodConfig);
      addTearDown(relaunched.close);
      await relaunched.restore();
      expect(relaunched.state, const SessionUnauthenticated(reason: SessionExpiredReason.noToken));
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.refreshToken.key), isNull);
      expect(await AppLocalStorage().read(StorageKeys.roles.key), isNull);
    });

    testWidgets('ends the session in mock mode when a request without a token gets 401', (tester) async {
      // The mock answers a protected request without a token with 401, as the server does. That happens when the
      // stored token is gone while the session is open, for example after a logout in another browser tab. No refresh
      // token is stored, so the refresh fails.
      TestEnv.authenticate();
      late BuildContext scope;
      await tester.pumpWidget(
        AppScope(
          dependencies: const AppDependencies(appConfig: AppConfig.test()),
          defaultLocale: const Locale('en'),
          child: Builder(
            builder: (context) {
              scope = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final session = scope.read<SessionCubit>();
      await tester.pumpAndSettle();
      expect(session.state, isA<SessionAuthenticated>());

      await FlutterSecureStorageAdapter().delete(SecureStorageKeys.jwtToken.key);
      final apiClient = scope.read<ApiClient>();
      // Dio runs each interceptor step on a timer, so the request moves only while fake time does.
      final request = expectLater(apiClient.get('/account'), throwsA(isA<UnauthorizedException>()));
      await tester.pump(Duration.zero);
      await request;

      expect(session.state, const SessionUnauthenticated(reason: SessionExpiredReason.expired));
    });

    testWidgets('keeps the session in mock mode when a 401 can be fixed by a token refresh', (tester) async {
      // A refresh token is stored, so the 401 starts a token refresh, as it does in production. The mock answers the
      // refresh like the server would, the request is sent again with the new token, and the user stays signed in.
      TestEnv.authenticate();
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'MOCK_REFRESH_TOKEN');
      late BuildContext scope;
      await tester.pumpWidget(
        AppScope(
          dependencies: const AppDependencies(appConfig: AppConfig.test()),
          defaultLocale: const Locale('en'),
          child: Builder(
            builder: (context) {
              scope = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final session = scope.read<SessionCubit>();
      await tester.pumpAndSettle();
      expect(session.state, isA<SessionAuthenticated>());

      await FlutterSecureStorageAdapter().delete(SecureStorageKeys.jwtToken.key);
      final apiClient = scope.read<ApiClient>();
      // Dio runs each interceptor step on a timer, so the request and the refresh move only while fake time does.
      final request = apiClient.get('/account');
      await tester.pump(Duration.zero);
      final response = await request;

      expect(response.statusCode, 200);
      expect(response.data, contains('"login": "admin"'));
      expect(session.state, isA<SessionAuthenticated>());
      // The tokens from assets/mock/POST_api_token_refresh.json.
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.jwtToken.key), 'MOCK_REFRESHED_TOKEN');
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.refreshToken.key), 'MOCK_REFRESH_TOKEN_NEW');
    });

    testWidgets('a wrong password neither refreshes nor ends the expired stored session', (tester) async {
      final dependencies = _CountingDependencies();
      final scope = await _pumpExpiredSession(tester, dependencies);
      final server = _ServerAdapter({
        'POST /authenticate': (401, {'title': 'Bad credentials'}),
        ..._refreshRoute,
      });
      scope.read<ApiClient>().instance.httpClientAdapter = server;

      final login = scope.read<LoginBloc>();
      login.add(const LoginFormSubmitted(username: 'admin', password: 'wrong-password'));
      await tester.pumpAndSettle();

      expect(login.state, isA<LoginErrorState>());
      expect(server.requests, ['POST /authenticate null'], reason: 'no stored token is sent, and none is refreshed');
      expect(dependencies.sessionExpiredCalls, 0);
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.refreshToken.key), 'stored-refresh-token');
      // A relaunch restores the session from secure storage, as AppScope does on launch.
      final relaunched = SessionCubit(secureStorage: FlutterSecureStorageAdapter(), appConfig: _prodConfig);
      addTearDown(relaunched.close);
      await relaunched.restore();
      expect(relaunched.state, const SessionUnauthenticated(reason: SessionExpiredReason.expired));
    });

    testWidgets('the right password signs in without sending the expired stored token', (tester) async {
      final dependencies = _CountingDependencies();
      final scope = await _pumpExpiredSession(tester, dependencies);
      final server = _ServerAdapter({
        'POST /authenticate': (200, {'id_token': _unexpiredJwt(), 'refresh_token': 'signed-in-refresh-token'}),
        'GET /account': (
          200,
          {
            'id': 'user-1',
            'login': 'admin',
            'authorities': ['ROLE_ADMIN'],
          },
        ),
        ..._refreshRoute,
      });
      scope.read<ApiClient>().instance.httpClientAdapter = server;

      final login = scope.read<LoginBloc>();
      login.add(const LoginFormSubmitted(username: 'admin', password: 'admin'));
      await tester.pumpAndSettle();

      expect(login.state, isA<LoginLoadedState>());
      expect(server.requests, ['POST /authenticate null', 'GET /account Bearer ${_unexpiredJwt()}']);
      expect(dependencies.sessionExpiredCalls, 0);
      // The sign-in replaces the expired session that restore() left stored.
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.refreshToken.key), 'signed-in-refresh-token');
      final relaunched = SessionCubit(secureStorage: FlutterSecureStorageAdapter(), appConfig: _prodConfig);
      addTearDown(relaunched.close);
      await relaunched.restore();
      expect(relaunched.state, const SessionAuthenticated(roles: {'ROLE_ADMIN'}));
    });

    testWidgets('provides the auth mode that AppDependencies carries', (tester) async {
      const authMode = OidcMisconfiguredAuthMode('OIDC_ISSUER is required');
      late BuildContext scope;
      await tester.pumpWidget(
        AppScope(
          dependencies: const AppDependencies(authMode: authMode),
          defaultLocale: const Locale('en'),
          child: Builder(
            builder: (context) {
              scope = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(scope.read<AuthMode>(), same(authMode));
    });

    // The logout, the idle timeout and an unrefreshable 401 must clear the same things, so they share one repository.
    testWidgets('logs out through the session repository that AppDependencies creates', (tester) async {
      final sessionRepository = _CountingSessionRepository();
      late BuildContext scope;
      await tester.pumpWidget(
        AppScope(
          dependencies: _SessionRepositoryDependencies(sessionRepository),
          defaultLocale: const Locale('en'),
          child: Builder(
            builder: (context) {
              scope = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(await scope.read<IAuthRepository>().logout(), isA<Success<void>>());

      expect(sessionRepository.clears, 1);
    });

    // The lifecycle checks read GET /app/config before sign-in. Were it not public, it would carry the expired token
    // restore() leaves stored, get 401, and spend the stored refresh token on a refresh that stores a working session
    // for a relaunch to restore.
    testWidgets('reading the app config before sign-in neither sends nor refreshes the expired stored session', (
      tester,
    ) async {
      final dependencies = _CountingDependencies();
      final scope = await _pumpExpiredSession(tester, dependencies);
      final server = _ServerAdapter({
        'GET /app/config': (200, {'minimumVersion': '1.0.0', 'maintenanceMode': false}),
        ..._refreshRoute,
      });
      final apiClient = scope.read<ApiClient>();
      apiClient.instance.httpClientAdapter = server;

      Result<AppConfigEntity>? result;
      LifecycleRepository(apiClient).fetchAppConfig().then((value) => result = value);
      await _pumpUntil(tester, () => result != null);

      expect(result, isA<Success<AppConfigEntity>>());
      expect(server.requests, ['GET /app/config null'], reason: 'no stored token is sent, and none is refreshed');
      expect(dependencies.sessionExpiredCalls, 0);
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.refreshToken.key), 'stored-refresh-token');
      // A relaunch restores the session from secure storage, as AppScope does on launch.
      final relaunched = SessionCubit(secureStorage: FlutterSecureStorageAdapter(), appConfig: _prodConfig);
      addTearDown(relaunched.close);
      await relaunched.restore();
      expect(relaunched.state, const SessionUnauthenticated(reason: SessionExpiredReason.expired));
    });

    // Regression: a token refresh still on its way when the session ended stored the rotated tokens after the wipe.
    // The request it sent again then succeeded, so nothing ended the session a second time, and a relaunch signed the
    // user back in.
    for (final (name, endSession) in <(String, Future<void> Function(BuildContext scope))>[
      (
        'the user logs out',
        (scope) async {
          final menu = scope.read<MenuBloc>();
          menu.add(const Logout());
          await menu.stream.firstWhere((state) => state.isLogout);
        },
      ),
      (
        'the idle timeout fires',
        (scope) => scope.read<SessionCubit>().endSession(reason: SessionExpiredReason.idleTimeout),
      ),
    ]) {
      testWidgets('leaves no session for a relaunch to restore when $name during a token refresh', (tester) async {
        final staleJwt = _unexpiredJwt();
        final freshJwt = _jwt(exp: 4102444801);
        await FlutterSecureStorageAdapter().write(SecureStorageKeys.jwtToken.key, staleJwt);
        await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'stored-refresh-token');
        await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN']);
        final dependencies = _CountingDependencies();
        late BuildContext scope;
        await tester.pumpWidget(
          AppScope(
            dependencies: dependencies,
            defaultLocale: const Locale('en'),
            child: Builder(
              builder: (context) {
                scope = context;
                return const SizedBox();
              },
            ),
          ),
        );
        final session = scope.read<SessionCubit>();
        await tester.pumpAndSettle();
        expect(session.state, isA<SessionAuthenticated>());
        final server = _RefreshRaceServer(staleJwt: staleJwt, freshJwt: freshJwt);
        final apiClient = scope.read<ApiClient>();
        apiClient.instance.httpClientAdapter = server;

        // The stored token is rejected, so the request starts a refresh, and the session ends before the server
        // answers the refresh.
        Object? outcome;
        apiClient
            .get('/account')
            .then<void>((response) => outcome = response, onError: (Object error) => outcome = error);
        await _pumpUntil(tester, () => server.refreshReceived.isCompleted);
        var ended = false;
        endSession(scope).then((_) => ended = true);
        await _pumpUntil(tester, () => ended);
        server.releaseRefresh.complete();
        await _pumpUntil(tester, () => outcome != null);

        expect(outcome, isA<UnauthorizedException>());
        expect(server.requests, ['GET /account Bearer stale', 'POST /api/token/refresh null']);
        expect(dependencies.sessionExpiredCalls, 0);
        expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.jwtToken.key), isNull);
        expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.refreshToken.key), isNull);
        // A relaunch restores the session from secure storage, as AppScope does on launch.
        final relaunched = SessionCubit(secureStorage: FlutterSecureStorageAdapter(), appConfig: _prodConfig);
        addTearDown(relaunched.close);
        await relaunched.restore();
        expect(relaunched.state, const SessionUnauthenticated(reason: SessionExpiredReason.noToken));
      });
    }

    // Regression: a request still on its way when the user signed out got its 401 after another user had signed in,
    // and it was sent again with the token of that user, so the change the first user saved was made as the second.
    testWidgets('does not send a request of the user who signed out again as the user who signed in since', (
      tester,
    ) async {
      final signedOutJwt = _jwt(exp: 4102444800, sub: 'user-one');
      final signedInJwt = _jwt(exp: 4102444800, sub: 'user-two');
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.jwtToken.key, signedOutJwt);
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'signed-out-refresh-token');
      await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN']);
      final dependencies = _CountingDependencies();
      late BuildContext scope;
      await tester.pumpWidget(
        AppScope(
          dependencies: dependencies,
          defaultLocale: const Locale('en'),
          child: Builder(
            builder: (context) {
              scope = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final session = scope.read<SessionCubit>();
      await tester.pumpAndSettle();
      expect(session.state, isA<SessionAuthenticated>());
      final server = _SignInRaceServer(signedOutJwt: signedOutJwt, signedInJwt: signedInJwt);
      final apiClient = scope.read<ApiClient>();
      apiClient.instance.httpClientAdapter = server;

      // The first user saves the account. Before the server answers, that user signs out and another signs in.
      Object? outcome;
      apiClient
          .post('/account', {'login': 'user-one', 'firstName': 'One'})
          .then<void>((response) => outcome = response, onError: (Object error) => outcome = error);
      await _pumpUntil(tester, () => server.saveReceived.isCompleted);
      final menu = scope.read<MenuBloc>();
      menu.add(const Logout());
      await _pumpUntil(tester, () => menu.state.isLogout);
      final login = scope.read<LoginBloc>();
      login.add(const LoginFormSubmitted(username: 'user-two', password: 'user-two-password'));
      await _pumpUntil(tester, () => login.state is LoginLoadedState);
      // The token of the first user expired on the way, so the server rejects the save.
      server.releaseSave.complete();
      await _pumpUntil(tester, () => outcome != null);

      expect(outcome, isA<UnauthorizedException>());
      expect(server.requests, [
        'POST /account Bearer signed-out-user',
        'POST /authenticate null',
        'GET /account Bearer signed-in-user',
      ]);
      expect(dependencies.sessionExpiredCalls, 0, reason: 'ending the session would sign out the user signed in now');
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.jwtToken.key), signedInJwt);
    });
  });

  group('AppScope single sign-on', () {
    testWidgets('an oidc build signs in through the OIDC client and stores the whole session', (tester) async {
      final expiresAt = DateTime.utc(2100);
      final dependencies = _OidcClientDependencies(
        authMode: OidcAuthMode(_oidcSettings),
        client: _FakeOidcClient(
          OidcSignedIn(
            tokens: OidcTokens(
              accessToken: 'sso-access-token',
              idToken: 'sso-id-token',
              refreshToken: 'sso-refresh-token',
              accessTokenExpiresAt: expiresAt,
            ),
            claims: const {
              'iss': 'https://id.example.com/realms/demo',
              'sub': 'subject-1',
              'email': 'jdoe@example.com',
            },
          ),
        ),
      );
      final scope = await _pumpScope(tester, dependencies);

      final login = scope.read<LoginBloc>();
      login.add(const SsoSignInRequested(browserDoneMessage: 'done'));
      await _pumpUntil(tester, () => login.state is LoginLoadedState);

      expect(login.state, const LoginLoadedState(username: 'jdoe@example.com', roles: ['ROLE_USER']));
      expect(dependencies.oidcClientsCreated, 1);
      final secure = FlutterSecureStorageAdapter();
      expect(await secure.read(SecureStorageKeys.jwtToken.key), 'sso-access-token');
      expect(await secure.read(SecureStorageKeys.refreshToken.key), 'sso-refresh-token');
      expect(await secure.read(SecureStorageKeys.oidcIdToken.key), 'sso-id-token');
      expect(readAccessTokenExpiry(await secure.read(SecureStorageKeys.accessTokenExpiresAt.key)), expiresAt);
      expect(scope.read<TokenRotation>(), isA<OidcTokenRotation>());
    });

    testWidgets('a jwt build creates no OIDC client', (tester) async {
      final dependencies = _OidcClientDependencies(
        authMode: const JwtAuthMode(),
        client: _FakeOidcClient(const OidcSignInCancelled()),
      );
      final scope = await _pumpScope(tester, dependencies);

      // LoginBloc is created on first read, which is when an oidc build reads the OIDC client.
      expect(scope.read<LoginBloc>().state, const LoginInitialState());

      expect(dependencies.oidcClientsCreated, 0);
    });

    testWidgets('a jwt build provides no OIDC client', (tester) async {
      final scope = await _pumpScope(tester, const AppDependencies(appConfig: AppConfig.test()));

      expect(() => scope.read<IOidcClient>(), throwsA(isA<ProviderNotFoundException>()));
    });
  });
}
