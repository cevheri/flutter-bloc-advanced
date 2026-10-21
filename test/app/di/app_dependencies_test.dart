import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

class _StubSecureStorage implements ISecureStorage {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
}

class _MemorySecureStorage implements ISecureStorage {
  final store = <String, String>{};
  @override
  Future<String?> read(String key) async => store[key];
  @override
  Future<void> write(String key, String value) async => store[key] = value;
  @override
  Future<void> delete(String key) async => store.remove(key);
  @override
  Future<void> deleteAll() async => store.clear();
}

/// Dependencies whose 401 predicate accepts no 401, as an app on a backend that narrows it does.
class _NoSessionExpiryDependencies extends AppDependencies {
  const _NoSessionExpiryDependencies() : super(appConfig: _prodConfig);

  @override
  SessionExpiredPredicate get sessionExpiredPredicate =>
      (_) => false;
}

/// A production config, so no MockInterceptor answers in place of the adapter the tests install.
const _prodConfig = AppConfig(
  environment: Environment.prod,
  apiBaseUrl: 'https://api.example.test',
  certificatePins: [],
  idleTimeout: null,
);

/// A TokenRotation that records each refresh token it is asked to rotate and refuses it.
class _FakeRotation implements TokenRotation {
  final sent = <String>[];

  @override
  Future<TokenRotationResult> rotate(String refreshToken) async {
    sent.add(refreshToken);
    return const RotationRefused();
  }
}

/// Answers every request with 401, and records each request as `METHOD path`.
class _UnauthorizedAdapter implements HttpClientAdapter {
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.method} ${options.path}');
    return ResponseBody.fromString('', 401);
  }

  @override
  void close({bool force = false}) {}
}

/// A secure store holding a signed-in session with a refresh token.
Future<_MemorySecureStorage> _signedInStorage() async {
  final storage = _MemorySecureStorage();
  await storage.write(SecureStorageKeys.jwtToken.key, 'ACCESS');
  await storage.write(SecureStorageKeys.refreshToken.key, 'REFRESH');
  return storage;
}

/// Sends a GET through [client], whose server answers [adapter]'s 401, and waits for it to fail.
Future<void> _getUnauthorized(ApiClient client, _UnauthorizedAdapter adapter) async {
  client.instance.httpClientAdapter = adapter;
  await expectLater(client.get('/api/users').timeout(const Duration(seconds: 5)), throwsA(anything));
}

final _oidcSession = AuthSession(
  idToken: 'ACCESS',
  username: 'alice',
  oidcIdToken: 'ID_TOKEN',
  accessTokenExpiresAt: DateTime.utc(2026, 10, 21, 12),
);

void main() {
  const dependencies = AppDependencies();

  test('AppDependencies defaults to jwt', () {
    expect(const AppDependencies().authMode, isA<JwtAuthMode>());
  });

  test('app dependencies expose account repository contract', () {
    expect(dependencies.createAccountRepository(TestEnv.apiClient()), isA<IAccountRepository>());
  });

  test('app dependencies expose auth repository contract', () {
    final sessionRepository = dependencies.createAuthSessionRepository(_StubSecureStorage(), sessionEndSignal: null);
    expect(dependencies.createAuthRepository(sessionRepository, TestEnv.apiClient()), isA<IAuthRepository>());
  });

  test('the session repository of an oidc build stores the OIDC ID token and the expiry', () async {
    final oidc = AppDependencies(
      authMode: OidcAuthMode(OidcSettings(issuer: Uri.parse('https://id.example.test/realms/demo'), clientId: 'app')),
    );
    final secureStorage = _MemorySecureStorage();

    await oidc.createAuthSessionRepository(secureStorage, sessionEndSignal: null).persist(_oidcSession);

    expect(secureStorage.store[SecureStorageKeys.oidcIdToken.key], 'ID_TOKEN');
    expect(secureStorage.store[SecureStorageKeys.accessTokenExpiresAt.key], isNotNull);
  });

  test('the session repository of a jwt build leaves the OIDC keys alone', () async {
    final secureStorage = _MemorySecureStorage();

    await dependencies.createAuthSessionRepository(secureStorage, sessionEndSignal: null).persist(_oidcSession);

    expect(secureStorage.store.keys, unorderedEquals([SecureStorageKeys.jwtToken.key]));
  });

  test('the default 401 predicate is any 401', () {
    expect(dependencies.sessionExpiredPredicate, same(isUnauthorized));
  });

  test('createApiClient ends the session on a 401 its refresh cannot fix', () async {
    final adapter = _UnauthorizedAdapter();
    var sessionExpiredCalls = 0;
    final client = const AppDependencies(appConfig: _prodConfig).createApiClient(
      await _signedInStorage(),
      onSessionExpired: () => sessionExpiredCalls++,
      tokenRefreshLock: null,
      rotatedTokensTakeBack: null,
    );

    await _getUnauthorized(client, adapter);

    expect(adapter.requests, ['GET /api/users', 'POST /api/token/refresh']);
    expect(sessionExpiredCalls, 1);
  });

  test('createApiClient uses sessionExpiredPredicate', () async {
    final adapter = _UnauthorizedAdapter();
    var sessionExpiredCalls = 0;
    final client = const _NoSessionExpiryDependencies().createApiClient(
      await _signedInStorage(),
      onSessionExpired: () => sessionExpiredCalls++,
      tokenRefreshLock: null,
      rotatedTokensTakeBack: null,
    );

    await _getUnauthorized(client, adapter);

    expect(adapter.requests, ['GET /api/users'], reason: 'a 401 the predicate refuses starts no refresh');
    expect(sessionExpiredCalls, 0);
  });

  test('createOidcApiClient routes a 401 to the given rotation', () async {
    final adapter = _UnauthorizedAdapter();
    final rotation = _FakeRotation();
    var sessionExpiredCalls = 0;
    final client = const AppDependencies(appConfig: _prodConfig).createOidcApiClient(
      await _signedInStorage(),
      onSessionExpired: () => sessionExpiredCalls++,
      tokenRotation: rotation,
      tokenRefreshLock: null,
      rotatedTokensTakeBack: null,
    );

    await _getUnauthorized(client, adapter);

    expect(rotation.sent, ['REFRESH']);
    expect(adapter.requests, ['GET /api/users'], reason: 'the backend refresh endpoint is not called');
    expect(sessionExpiredCalls, 1, reason: 'the fake rotation refuses');
  });

  test('createOidcApiClient uses sessionExpiredPredicate', () async {
    final adapter = _UnauthorizedAdapter();
    final rotation = _FakeRotation();
    var sessionExpiredCalls = 0;
    final client = const _NoSessionExpiryDependencies().createOidcApiClient(
      await _signedInStorage(),
      onSessionExpired: () => sessionExpiredCalls++,
      tokenRotation: rotation,
      tokenRefreshLock: null,
      rotatedTokensTakeBack: null,
    );

    await _getUnauthorized(client, adapter);

    expect(rotation.sent, isEmpty);
    expect(sessionExpiredCalls, 0);
  });

  test('app dependencies expose lifecycle repository contract', () {
    expect(dependencies.createLifecycleRepository(TestEnv.apiClient()), isA<ILifecycleRepository>());
  });

  test('app dependencies expose user repository contract', () {
    expect(dependencies.createUserRepository(TestEnv.apiClient()), isA<IUserRepository>());
  });
}
