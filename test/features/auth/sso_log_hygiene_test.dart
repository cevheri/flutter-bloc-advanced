@Tags(['widget'])
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/sso_sign_out_auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_key_value.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_redirect_uris.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_transaction_store.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:logging/logging.dart' as logging;

import '../../infrastructure/auth/oidc/support/fake_provider.dart';
import '../../support/printed_lines.dart';

final _settings = OidcSettings(issuer: Uri.parse(fakeIssuer), clientId: fakeClientId, roleClaim: 'realm_access.roles');

/// The test config in an oidc build whose client talks to [provider] through the fake platform.
class _OidcDependencies extends AppDependencies {
  _OidcDependencies(this.provider) : super(appConfig: const AppConfig.test(), authMode: OidcAuthMode(_settings));

  final FakeProvider provider;

  @override
  IOidcClient createOidcClient(OidcSettings settings) => OidcClient(
    settings: settings,
    loginPath: ApplicationRoutesConstants.login,
    launchUrl: (_) async => fail('an iOS sign-in never launches a URL itself'),
    store: OidcTransactionStore(persistent: MemoryKeyValue(), tab: MemoryKeyValue()),
    httpClient: provider.client,
    platform: OidcPlatformKind.ios,
    pageUri: Uri.parse('http://localhost:8081/'),
    cancelAndroidFlow: () async => fail('an iOS sign-in never cancels an Android flow'),
  );
}

/// The API server: 401 to a request whose bearer is in [rejected], as to an expired access token, and 200 to any
/// other, so the request never reaches the mock interceptor behind it.
class _ServerStub extends Interceptor {
  final rejected = <String>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final authorization = options.headers['Authorization'] as String?;
    if (authorization != null && rejected.contains(authorization.replaceFirst('Bearer ', ''))) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 401),
        ),
        true,
      );
      return;
    }
    handler.resolve(Response(requestOptions: options, statusCode: 200, data: '{}'));
  }
}

/// Every line the three log sources give while [body] runs: what the zone prints (AppLogger's console output among
/// it), the output events of package:logger, and each package:logging record at every level, with its error and
/// stack trace.
Future<List<String>> _capturedLogs(Future<void> Function() body) async {
  final loggerLines = <String>[];
  void collect(OutputEvent event) => loggerLines.addAll(event.lines);
  Logger.addOutputListener(collect);
  addTearDown(() => Logger.removeOutputListener(collect));

  final records = <String>[];
  final rootLevel = logging.Logger.root.level;
  logging.Logger.root.level = logging.Level.ALL;
  addTearDown(() => logging.Logger.root.level = rootLevel);
  final subscription = logging.Logger.root.onRecord.listen((record) {
    records.add('${record.loggerName}/${record.level.name}: ${record.message}');
    if (record.error case final error?) records.add(error.toString());
    if (record.stackTrace case final stackTrace?) records.add(stackTrace.toString());
  });
  addTearDown(subscription.cancel);

  final printed = await printedLines(body);
  return [...printed, ...loggerLines, ...records];
}

void _expectNoSecret(List<String> lines, Set<String> secrets) {
  for (final secret in secrets) {
    expect(secret, isNotEmpty);
    final leaks = [
      for (final line in lines)
        if (line.contains(secret)) line,
    ];
    expect(leaks, isEmpty, reason: 'a log line carries the secret $secret');
  }
}

void main() {
  test('a sign-in, a refresh, a logout and their failures log no token, code, verifier, state or nonce', () async {
    final provider = FakeProvider();
    final platform = installFakePlatform(provider);
    final issued = <String>{};
    http.Response recordTokens(http.Response answer) {
      final body = jsonDecode(answer.body) as Map<String, dynamic>;
      for (final key in const ['access_token', 'refresh_token', 'id_token']) {
        if (body[key] case final String token) issued.add(token);
      }
      return answer;
    }

    provider
      ..codeAnswer = (() => recordTokens(provider.tokenAnswer(nonce: provider.nonce)))
      ..refreshAnswer = (() => recordTokens(provider.tokenAnswer()));

    final dependencies = _OidcDependencies(provider);
    final secureStorage = FlutterSecureStorageAdapter();
    final client = dependencies.createOidcClient(_settings);
    final sessions = dependencies.createAuthSessionRepository(secureStorage, sessionEndSignal: null);
    final rotation = dependencies.createOidcTokenRotation(client, secureStorage);
    var sessionsExpired = 0;
    final apiClient = dependencies.createOidcApiClient(
      secureStorage,
      onSessionExpired: () async {
        sessionsExpired++;
        await sessions.clear();
      },
      tokenRotation: rotation,
      tokenRefreshLock: null,
      rotatedTokensTakeBack: null,
    );
    final server = _ServerStub();
    final dio = apiClient.instance;
    dio.interceptors.insert(dio.interceptors.length - 1, server);
    final ssoRepository = dependencies.createSsoAuthRepository(client, sessions, _settings);
    final signOutRepository = SsoSignOutAuthRepository(
      inner: dependencies.createAuthRepository(sessions, apiClient),
      client: client,
      secureStorage: secureStorage,
      settings: _settings,
    );
    Future<String?> stored(SecureStorageKeys key) => secureStorage.read(key.key);
    // The error a caller of the API gets, which a page or a BLoC may log in turn.
    Object? apiError;

    final lines = await _capturedLogs(() async {
      // A code exchange the provider refuses.
      final defaultCodeAnswer = provider.codeAnswer;
      provider.codeAnswer = () => FakeProvider.errorAnswer('invalid_grant');
      expect(await ssoRepository.signIn(browserDoneMessage: 'done'), isA<SsoSignInRejected>());
      provider.codeAnswer = defaultCodeAnswer;

      // A sign-in, then a 401 that a refresh fixes.
      expect(await ssoRepository.signIn(browserDoneMessage: 'done'), isA<SsoSignInSucceeded>());
      server.rejected.add((await stored(SecureStorageKeys.jwtToken))!);
      expect((await apiClient.get('/account')).statusCode, 200);
      expect(provider.tokenRequests, hasLength(3));

      // A logout that ends the provider session with the refreshed ID token as its hint.
      expect(await signOutRepository.logout(), isA<Success<void>>());
      expect(issued, contains(platform.endSessionRequests.single.idTokenHint));

      // A sign-in, then a 401 whose refresh the provider refuses, which ends the session.
      expect(await ssoRepository.signIn(browserDoneMessage: 'done'), isA<SsoSignInSucceeded>());
      server.rejected.add((await stored(SecureStorageKeys.jwtToken))!);
      provider.refreshAnswer = () => FakeProvider.errorAnswer('invalid_grant');
      apiError = await apiClient.get('/account').then<Object?>((_) => null, onError: (Object error) => error);
      expect(apiError, isNotNull);
      expect(sessionsExpired, 1);
      expect(await stored(SecureStorageKeys.jwtToken), isNull);
    });

    expect(issued, hasLength(9), reason: 'three token answers, each with an access, a refresh and an ID token');
    final verifiers = [for (final request in provider.tokenRequests) ?FakeProvider.form(request)['code_verifier']];
    expect(verifiers, hasLength(3), reason: 'three code exchanges, the refused one among them');
    expect(platform.authorizeRequests, hasLength(3));
    expect(lines, contains(contains('Signed in through the identity provider')), reason: 'the capture saw no log');
    _expectNoSecret(
      [...lines, apiError.toString()],
      {
        ...issued,
        FakeOidcPlatform.code,
        for (final request in platform.authorizeRequests) ...[request.state!, request.nonce!],
        ...verifiers,
      },
    );
  });

  testWidgets('a callback URL the platform pushes logs neither its code nor its state', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    final provider = FakeProvider();
    installFakePlatform(provider);

    final lines = await _capturedLogs(() async {
      await tester.pumpWidget(App(language: 'en', dependencies: _OidcDependencies(provider)));
      await tester.pumpAndSettle();

      // The platform pushes a route the way iOS delivers a custom scheme link (app_router_test.dart).
      final message = SystemChannels.navigation.codec.encodeMethodCall(
        const MethodCall('pushRouteInformation', <String, Object?>{
          'location': '/oauth2redirect?code=SECRETCODE&state=SECRETSTATE',
          'state': null,
        }),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        message,
        (_) {},
      );
      await tester.pumpAndSettle();
    });

    expect(find.byType(LoginScreen), findsOneWidget);
    final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
    expect(router.state.uri.toString(), ApplicationRoutesConstants.login);
    expect(lines, isNotEmpty, reason: 'the capture saw no log');
    _expectNoSecret(lines, {'SECRETCODE', 'SECRETSTATE'});
  });
}
