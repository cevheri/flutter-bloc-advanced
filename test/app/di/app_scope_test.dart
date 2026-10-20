@Tags(['widget'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/di/app_scope.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
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

String _jwt({required int exp}) {
  String part(Map<String, Object> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': 'admin', 'exp': exp})}.signature';
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
      await tester.runAsync(() async {
        // The session ends once the stored session is cleared, which can finish after the request has failed.
        final ended = session.stream.firstWhere((state) => state is SessionUnauthenticated);
        await expectLater(apiClient.get('/api/account'), throwsA(isA<UnauthorizedException>()));
        await ended;
      });

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
      await tester.runAsync(() => expectLater(apiClient.get('/account'), throwsA(isA<UnauthorizedException>())));

      expect(session.state, const SessionUnauthenticated(reason: SessionExpiredReason.expired));
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
  });
}
