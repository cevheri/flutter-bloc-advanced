import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory ISecureStorage for tests.
class _MemorySecureStorage implements ISecureStorage {
  final Map<String, String> _store = {};
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async => _store[key] = value;
  @override
  Future<void> delete(String key) async => _store.remove(key);
  @override
  Future<void> deleteAll() async => _store.clear();
}

/// ISecureStorage whose read() always throws. Exercises the
/// Result-on-snapshot-failure contract in persist().
class _ReadThrowsSecureStorage implements ISecureStorage {
  @override
  Future<String?> read(String key) async => throw StateError('boom on read $key');
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
}

/// ISecureStorage that throws on the configured delete key. Exercises
/// the best-effort sequential cleanup path in clear().
class _SelectiveFailSecureStorage implements ISecureStorage {
  _SelectiveFailSecureStorage({required this.failOn});
  final String failOn;
  final Map<String, String> _store = {};
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async => _store[key] = value;
  @override
  Future<void> delete(String key) async {
    if (key == failOn) throw StateError('boom on $key');
    _store.remove(key);
  }

  @override
  Future<void> deleteAll() async => _store.clear();
}

/// Storage fake that lets a test choose which key's `save` should fail.
class _FlakyStorage implements AppLocalStorage {
  _FlakyStorage(this._inner, this.failOnKey);
  final AppLocalStorage _inner;
  final String failOnKey;
  final removedKeys = <String>[];
  @override
  Future<bool> save(String key, dynamic value) async {
    if (key == failOnKey) return false;
    return _inner.save(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    removedKeys.add(key);
    return _inner.remove(key);
  }

  @override
  Future<dynamic> read(String key) => _inner.read(key);
  @override
  Future<void> clear() => _inner.clear();
  @override
  void setPreferencesInstance(SharedPreferences prefs) => _inner.setPreferencesInstance(prefs);
}

void main() {
  late AppLocalStorage storage;
  late _MemorySecureStorage secure;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = AppLocalStorage();
    storage.setPreferencesInstance(await SharedPreferences.getInstance());
    secure = _MemorySecureStorage();
  });

  group('AuthSessionRepository', () {
    test('persist routes tokens to secure storage, username/roles to local', () async {
      final repo = AuthSessionRepository(secureStorage: secure, storage: storage);
      const session = AuthSession(idToken: 'TOKEN', refreshToken: 'REFRESH', username: 'alice', roles: ['ROLE_USER']);

      final result = await repo.persist(session);

      expect(result, isA<Success<void>>());
      expect(await secure.read(SecureStorageKeys.jwtToken.key), 'TOKEN');
      expect(await secure.read(SecureStorageKeys.refreshToken.key), 'REFRESH');
      expect(await storage.read(StorageKeys.username.key), 'alice');
      expect(await storage.read(StorageKeys.roles.key), ['ROLE_USER']);
    });

    test('persist deletes refreshToken from secure storage when null', () async {
      await secure.write(SecureStorageKeys.refreshToken.key, 'STALE');
      final repo = AuthSessionRepository(secureStorage: secure, storage: storage);
      const session = AuthSession(idToken: 'TOKEN', username: 'alice');

      await repo.persist(session);

      expect(await secure.read(SecureStorageKeys.refreshToken.key), isNull);
    });

    test('persist rolls back secure writes when a local write fails', () async {
      final flaky = _FlakyStorage(storage, StorageKeys.username.key);
      final repo = AuthSessionRepository(secureStorage: secure, storage: flaky);
      const session = AuthSession(idToken: 'TOKEN', refreshToken: 'REFRESH', username: 'alice');

      final result = await repo.persist(session);

      expect(result, isA<Failure<void>>());
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull, reason: 'secure token rolled back');
      expect(await secure.read(SecureStorageKeys.refreshToken.key), isNull, reason: 'secure refresh rolled back');
      expect(await storage.read(StorageKeys.username.key), isNull);
    });

    test('rollback restores prior secure values, not just deletes', () async {
      // Pre-existing session in secure storage.
      await secure.write(SecureStorageKeys.jwtToken.key, 'OLD_JWT');
      await secure.write(SecureStorageKeys.refreshToken.key, 'OLD_REFRESH');

      // New persist that will fail on the local username write.
      final flaky = _FlakyStorage(storage, StorageKeys.username.key);
      final repo = AuthSessionRepository(secureStorage: secure, storage: flaky);
      const session = AuthSession(idToken: 'NEW_JWT', refreshToken: 'NEW_REFRESH', username: 'bob');

      final result = await repo.persist(session);

      expect(result, isA<Failure<void>>());
      // Rollback restored prior values rather than deleting them.
      expect(await secure.read(SecureStorageKeys.jwtToken.key), 'OLD_JWT');
      expect(await secure.read(SecureStorageKeys.refreshToken.key), 'OLD_REFRESH');
    });

    test('rollback restores prior username and roles on local-write failure', () async {
      // Pre-existing local session: simulates a re-login where the user
      // was already authenticated and persist() is invoked again with
      // new tokens but fails partway through the local writes.
      await storage.save(StorageKeys.username.key, 'OLD_USER');
      await storage.save(StorageKeys.roles.key, ['ROLE_OLD']);

      final flaky = _FlakyStorage(storage, StorageKeys.roles.key);
      final repo = AuthSessionRepository(secureStorage: secure, storage: flaky);
      const session = AuthSession(idToken: 'NEW_JWT', username: 'NEW_USER', roles: ['ROLE_NEW']);

      final result = await repo.persist(session);

      expect(result, isA<Failure<void>>());
      // username was written but rollback restored the prior value
      // rather than deleting (which would have wiped the old session).
      expect(await storage.read(StorageKeys.username.key), 'OLD_USER');
      expect(await storage.read(StorageKeys.roles.key), ['ROLE_OLD']);
    });

    test('rollback restores stale refreshToken that persist had deleted', () async {
      // Pre-existing refresh token; new session has none, so persist would
      // delete it. If a later write fails, rollback must restore it.
      await secure.write(SecureStorageKeys.refreshToken.key, 'STALE_REFRESH');

      final flaky = _FlakyStorage(storage, StorageKeys.username.key);
      final repo = AuthSessionRepository(secureStorage: secure, storage: flaky);
      const session = AuthSession(idToken: 'NEW_JWT', username: 'bob');

      final result = await repo.persist(session);

      expect(result, isA<Failure<void>>());
      expect(await secure.read(SecureStorageKeys.refreshToken.key), 'STALE_REFRESH');
    });

    test('persist returns Failure (does not throw) when snapshot read fails', () async {
      // ISecureStorage.read is allowed to throw on platform failure.
      // Repository contract: persist always returns a Result — never
      // propagates a raw exception, including from the pre-write
      // snapshot.
      final flaky = _ReadThrowsSecureStorage();
      final repo = AuthSessionRepository(secureStorage: flaky, storage: storage);
      const session = AuthSession(idToken: 'TOKEN', username: 'alice');

      final result = await repo.persist(session);

      expect(result, isA<Failure<void>>());
    });

    test('clear keeps wiping even if one secure delete throws', () async {
      // _MemorySecureStorage that selectively throws on one key — proves
      // clear() doesn't bail on the first failure and leave the other
      // secure key behind.
      final flaky = _SelectiveFailSecureStorage(failOn: SecureStorageKeys.jwtToken.key);
      await flaky.write(SecureStorageKeys.refreshToken.key, 'REFRESH');
      await storage.save(StorageKeys.username.key, 'alice');
      final repo = AuthSessionRepository(secureStorage: flaky, storage: storage);

      final result = await repo.clear();

      expect(result, isA<Failure<void>>(), reason: 'partial failure surfaces as Failure');
      expect(await flaky.read(SecureStorageKeys.refreshToken.key), isNull);
      expect(await storage.read(StorageKeys.username.key), isNull, reason: 'local clear still ran');
    });

    test('clear empties both backends', () async {
      await secure.write(SecureStorageKeys.jwtToken.key, 'TOKEN');
      await storage.save(StorageKeys.username.key, 'alice');
      final repo = AuthSessionRepository(secureStorage: secure, storage: storage);

      final result = await repo.clear();

      expect(result, isA<Success<void>>());
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await storage.read(StorageKeys.username.key), isNull);
    });
  });
}
