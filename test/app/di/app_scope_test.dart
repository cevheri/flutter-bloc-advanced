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
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
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
String _unexpiredJwt() {
  String part(Map<String, Object> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': 'admin', 'exp': 4102444800})}.signature';
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
  });
}
