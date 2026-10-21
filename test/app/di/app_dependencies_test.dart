import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
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
    final sessionRepository = dependencies.createAuthSessionRepository(_StubSecureStorage());
    expect(dependencies.createAuthRepository(sessionRepository, TestEnv.apiClient()), isA<IAuthRepository>());
  });

  test('the session repository of an oidc build stores the OIDC ID token and the expiry', () async {
    final oidc = AppDependencies(
      authMode: OidcAuthMode(OidcSettings(issuer: Uri.parse('https://id.example.test/realms/demo'), clientId: 'app')),
    );
    final secureStorage = _MemorySecureStorage();

    await oidc.createAuthSessionRepository(secureStorage).persist(_oidcSession);

    expect(secureStorage.store[SecureStorageKeys.oidcIdToken.key], 'ID_TOKEN');
    expect(secureStorage.store[SecureStorageKeys.accessTokenExpiresAt.key], isNotNull);
  });

  test('the session repository of a jwt build leaves the OIDC keys alone', () async {
    final secureStorage = _MemorySecureStorage();

    await dependencies.createAuthSessionRepository(secureStorage).persist(_oidcSession);

    expect(secureStorage.store.keys, unorderedEquals([SecureStorageKeys.jwtToken.key]));
  });

  test('app dependencies expose lifecycle repository contract', () {
    expect(dependencies.createLifecycleRepository(TestEnv.apiClient()), isA<ILifecycleRepository>());
  });

  test('app dependencies expose user repository contract', () {
    expect(dependencies.createUserRepository(TestEnv.apiClient()), isA<IUserRepository>());
  });
}
