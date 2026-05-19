import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../test_utils.dart';

/// Storage fake that lets a test choose which key's `save` should fail,
/// so we can simulate a partial-write failure and observe the rollback.
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

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = AppLocalStorage();
    storage.setPreferencesInstance(await SharedPreferences.getInstance());
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  group('AuthSessionRepository', () {
    test('persist writes jwtToken, username, and roles', () async {
      final repo = AuthSessionRepository(storage: storage);
      const session = AuthSession(idToken: 'TOKEN', refreshToken: 'REFRESH', username: 'alice', roles: ['ROLE_USER']);

      final result = await repo.persist(session);

      expect(result, isA<Success<void>>());
      expect(await storage.read(StorageKeys.jwtToken.key), 'TOKEN');
      expect(await storage.read(StorageKeys.refreshToken.key), 'REFRESH');
      expect(await storage.read(StorageKeys.username.key), 'alice');
      expect(await storage.read(StorageKeys.roles.key), ['ROLE_USER']);
    });

    test('persist skips refreshToken when null', () async {
      final repo = AuthSessionRepository(storage: storage);
      const session = AuthSession(idToken: 'TOKEN', username: 'alice');

      await repo.persist(session);

      expect(await storage.read(StorageKeys.jwtToken.key), 'TOKEN');
      expect(await storage.read(StorageKeys.refreshToken.key), isNull);
    });

    test('persist rolls back previously-written keys when a later write fails', () async {
      final flaky = _FlakyStorage(storage, StorageKeys.username.key);
      final repo = AuthSessionRepository(storage: flaky);
      const session = AuthSession(idToken: 'TOKEN', refreshToken: 'REFRESH', username: 'alice', roles: ['ROLE_USER']);

      final result = await repo.persist(session);

      expect(result, isA<Failure<void>>());
      // After rollback, the partial writes that succeeded (jwtToken,
      // refreshToken) must have been removed; never a half-persisted
      // session.
      expect(await storage.read(StorageKeys.jwtToken.key), isNull);
      expect(await storage.read(StorageKeys.refreshToken.key), isNull);
      expect(await storage.read(StorageKeys.username.key), isNull);
      expect(await storage.read(StorageKeys.roles.key), isNull);
      expect(flaky.removedKeys, containsAll([StorageKeys.jwtToken.key, StorageKeys.refreshToken.key]));
    });

    test('persist removes a stale refreshToken when the new session has none', () async {
      final repo = AuthSessionRepository(storage: storage);
      await storage.save(StorageKeys.refreshToken.key, 'STALE_REFRESH');
      const session = AuthSession(idToken: 'TOKEN', username: 'alice');

      final result = await repo.persist(session);

      expect(result, isA<Success<void>>());
      expect(await storage.read(StorageKeys.refreshToken.key), isNull);
    });

    test('clear empties the storage', () async {
      final repo = AuthSessionRepository(storage: storage);
      await storage.save(StorageKeys.jwtToken.key, 'TOKEN');
      await storage.save(StorageKeys.username.key, 'alice');

      final result = await repo.clear();

      expect(result, isA<Success<void>>());
      expect(await storage.read(StorageKeys.jwtToken.key), isNull);
      expect(await storage.read(StorageKeys.username.key), isNull);
    });
  });
}
