import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';
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

/// ISecureStorage whose write of [failOnWrite] stores the value and then throws, as an adapter that fails after it
/// changed the platform store. Exercises the rollback of a key whose write failed.
class _WriteFailSecureStorage extends _MemorySecureStorage {
  _WriteFailSecureStorage({required this.failOnWrite});
  final String failOnWrite;
  @override
  Future<void> write(String key, String value) async {
    await super.write(key, value);
    if (key == failOnWrite) throw StateError('boom on write $key');
  }
}

/// In-memory ISecureStorage that records every call as `<method> <key>`, in order.
class _CallRecordingSecureStorage extends _MemorySecureStorage {
  final calls = <String>[];
  @override
  Future<String?> read(String key) {
    calls.add('read $key');
    return super.read(key);
  }

  @override
  Future<void> write(String key, String value) {
    calls.add('write $key');
    return super.write(key, value);
  }

  @override
  Future<void> delete(String key) {
    calls.add('delete $key');
    return super.delete(key);
  }
}

/// [ISessionEndSignal] that runs [onNotify] when told that the session ends.
class _RecordingSessionEndSignal implements ISessionEndSignal {
  _RecordingSessionEndSignal(this.onNotify);

  final void Function() onNotify;

  @override
  void notifyEnded() => onNotify();

  @override
  Stream<DateTime> get endedElsewhere => const Stream.empty();

  @override
  Stream<void> get storeChanges => const Stream.empty();
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

/// Storage fake whose `remove` refuses one key, as SharedPreferences does when it cannot write.
class _RemoveRefusingStorage implements AppLocalStorage {
  _RemoveRefusingStorage(this._inner, this.refusedKey);
  final AppLocalStorage _inner;
  final String refusedKey;
  @override
  Future<bool> save(String key, dynamic value) => _inner.save(key, value);
  @override
  Future<bool> remove(String key) async => key == refusedKey ? false : _inner.remove(key);
  @override
  Future<dynamic> read(String key) => _inner.read(key);
  @override
  Future<void> clear() => _inner.clear();
  @override
  void setPreferencesInstance(SharedPreferences prefs) => _inner.setPreferencesInstance(prefs);
}

/// Cache whose `clear` fails, as SharedPrefsCacheStorage.clear does when SharedPreferences keeps an entry.
class _FailingClearCacheStorage implements ICacheStorage {
  @override
  Future<CacheEntry?> read(String key) async => null;
  @override
  Future<void> write(String key, String data, {Duration? ttl}) async {}
  @override
  Future<void> remove(String key) async {}
  @override
  Future<void> clear() async => throw StateError('Cache clear left 1 of 2 entries');
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

    test('clear removes the session from both backends', () async {
      await secure.write(SecureStorageKeys.jwtToken.key, 'TOKEN');
      await storage.save(StorageKeys.username.key, 'alice');
      final repo = AuthSessionRepository(secureStorage: secure, storage: storage);

      final result = await repo.clear();

      expect(result, isA<Success<void>>());
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await storage.read(StorageKeys.username.key), isNull);
    });

    test('clear keeps the device preferences', () async {
      await storage.save(StorageKeys.language.key, 'tr');
      await storage.save(StorageKeys.theme.key, 'nature');
      await storage.save(StorageKeys.brightness.key, 'dark');
      await storage.save(StorageKeys.sidebarCollapsed.key, 'true');
      final repo = AuthSessionRepository(secureStorage: secure, storage: storage);
      await repo.persist(const AuthSession(idToken: 'TOKEN', username: 'alice', roles: ['ROLE_USER']));

      final result = await repo.clear();

      expect(result, isA<Success<void>>());
      expect(await storage.read(StorageKeys.language.key), 'tr');
      expect(await storage.read(StorageKeys.theme.key), 'nature');
      expect(await storage.read(StorageKeys.brightness.key), 'dark');
      expect(await storage.read(StorageKeys.sidebarCollapsed.key), 'true');
    });

    // Guards the switch from wiping everything to removing session keys: runSessionMigration copies back a kept token.
    test('clear removes the session keys, also the plaintext tokens a failed migration left behind', () async {
      final repo = AuthSessionRepository(secureStorage: secure, storage: storage);
      await repo.persist(const AuthSession(idToken: 'TOKEN', refreshToken: 'REFRESH', username: 'alice', roles: ['R']));
      // Releases before the move to secure storage kept the tokens here, and runSessionMigration leaves them when
      // it cannot remove them.
      await storage.save('jwtToken', 'PLAINTEXT_TOKEN');
      await storage.save('refreshToken', 'PLAINTEXT_REFRESH');

      final result = await repo.clear();

      expect(result, isA<Success<void>>());
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await secure.read(SecureStorageKeys.refreshToken.key), isNull);
      expect(await storage.read(StorageKeys.username.key), isNull);
      expect(await storage.read(StorageKeys.roles.key), isNull);
      expect(await storage.read('jwtToken'), isNull);
      expect(await storage.read('refreshToken'), isNull);
    });

    // Guards the switch from wiping everything to removing session keys: the cache is no longer wiped with them.
    test('clear removes the cached responses', () async {
      final cache = SharedPrefsCacheStorage();
      await cache.write('GET_/account', '{"login":"alice"}');
      await cache.write('GET_/admin/users', '[{"login":"bob"}]');
      final repo = AuthSessionRepository(secureStorage: secure, storage: storage, cacheStorage: cache);

      final result = await repo.clear();

      expect(result, isA<Success<void>>());
      expect(await cache.read('GET_/account'), isNull);
      expect(await cache.read('GET_/admin/users'), isNull);
    });

    test('clear reports cached responses that stay behind and still removes the session', () async {
      final repo = AuthSessionRepository(
        secureStorage: secure,
        storage: storage,
        cacheStorage: _FailingClearCacheStorage(),
      );
      await repo.persist(const AuthSession(idToken: 'TOKEN', refreshToken: 'REFRESH', username: 'alice'));

      final result = await repo.clear();

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error.message, contains('Cache clear left 1 of 2 entries'));
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await secure.read(SecureStorageKeys.refreshToken.key), isNull);
      expect(await storage.read(StorageKeys.username.key), isNull);
    });

    test('clear reports a session key it cannot remove and still removes the rest', () async {
      final cache = SharedPrefsCacheStorage();
      await cache.write('GET_/account', '{"login":"alice"}');
      final refusing = _RemoveRefusingStorage(storage, StorageKeys.username.key);
      final repo = AuthSessionRepository(secureStorage: secure, storage: refusing, cacheStorage: cache);
      await repo.persist(const AuthSession(idToken: 'TOKEN', username: 'alice', roles: ['ROLE_USER']));
      await storage.save('jwtToken', 'PLAINTEXT_TOKEN');

      final result = await repo.clear();

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error.message, contains('username'));
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await storage.read(StorageKeys.roles.key), isNull);
      expect(await storage.read('jwtToken'), isNull);
      expect(await cache.read('GET_/account'), isNull);
    });

    // A token refresh drops its rotated tokens once the session it was asked for has ended. Unless the wipe counts as
    // that end from its first storage call until it finishes, and a generation read while it ran counts as ended once
    // it finishes, a refresh can store its tokens during or after the wipe, and a relaunch restores the session.
    test('clear ends the session generation for the whole wipe and again when it finishes', () async {
      final before = SessionGeneration.current;
      final recording = _GenerationRecordingSecureStorage();
      final cache = _GenerationRecordingCacheStorage();
      await recording.write(SecureStorageKeys.jwtToken.key, 'TOKEN');
      recording.calls.clear();

      await AuthSessionRepository(secureStorage: recording, storage: storage, cacheStorage: cache).clear();

      expect(SessionGeneration.hasEnded(before), isTrue);
      // The token deletes and the cache clear, the first and the last storage calls of the wipe.
      expect(recording.calls, hasLength(2));
      expect(recording.calls.map((call) => call.ended), everyElement(isTrue));
      expect(cache.endedWhenCleared, isTrue);
      expect(SessionGeneration.hasEnded(recording.calls.first.generation), isTrue);
    });
  });

  // On web the other browser tabs share the stored session but count their own generation. A refresh on its way in one
  // of them stores its rotated tokens after this wipe unless it hears of the end.
  group('AuthSessionRepository and the other browser tabs', () {
    test('clear tells the other tabs that the session ends, before its first storage call', () async {
      final recording = _CallRecordingSecureStorage();
      await recording.write(SecureStorageKeys.jwtToken.key, 'TOKEN');
      recording.calls.clear();
      final signal = _RecordingSessionEndSignal(() => recording.calls.add('told the other tabs'));

      await AuthSessionRepository(secureStorage: recording, storage: storage, sessionEndSignal: signal).clear();

      expect(recording.calls.first, 'told the other tabs');
      expect(recording.calls.where((call) => call == 'told the other tabs'), hasLength(1));
      expect(recording.calls[1], 'delete ${SecureStorageKeys.jwtToken.key}');
    });

    test('clear still wipes the session when telling the other tabs fails, and reports it', () async {
      await secure.write(SecureStorageKeys.jwtToken.key, 'TOKEN');
      await secure.write(SecureStorageKeys.refreshToken.key, 'REFRESH');
      final signal = _RecordingSessionEndSignal(() => throw StateError('channel closed'));

      final result = await AuthSessionRepository(
        secureStorage: secure,
        storage: storage,
        sessionEndSignal: signal,
      ).clear();

      expect(result, isA<Failure<void>>());
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await secure.read(SecureStorageKeys.refreshToken.key), isNull);
    });
  });

  group('AuthSessionRepository with the OIDC keys', () {
    final expiresAt = DateTime.utc(2026, 10, 21, 12);
    final idTokenKey = SecureStorageKeys.oidcIdToken.key;
    final expiryKey = SecureStorageKeys.accessTokenExpiresAt.key;

    test('persists the OIDC ID token and the expiry next to the tokens', () async {
      final recording = _CallRecordingSecureStorage();
      final repo = AuthSessionRepository(secureStorage: recording, storage: storage, oidcKeys: true);
      final session = AuthSession(
        idToken: 'ACCESS',
        refreshToken: 'REFRESH',
        username: 'alice',
        oidcIdToken: 'ID_TOKEN',
        accessTokenExpiresAt: expiresAt,
      );

      final result = await repo.persist(session);

      expect(result, isA<Success<void>>());
      expect(recording.calls.where((call) => call.startsWith('write ')), [
        'write ${SecureStorageKeys.jwtToken.key}',
        'write ${SecureStorageKeys.refreshToken.key}',
        'write $idTokenKey',
        'write $expiryKey',
      ]);
      expect(await recording.read(idTokenKey), 'ID_TOKEN');
      expect(await recording.read(expiryKey), encodeAccessTokenExpiry(expiresAt));
      expect(readAccessTokenExpiry(await recording.read(expiryKey)), expiresAt);
    });

    test('deletes a stored OIDC ID token and expiry when the new session has none', () async {
      await secure.write(idTokenKey, 'OLD_ID_TOKEN');
      await secure.write(expiryKey, encodeAccessTokenExpiry(expiresAt));
      final repo = AuthSessionRepository(secureStorage: secure, storage: storage, oidcKeys: true);

      final result = await repo.persist(const AuthSession(idToken: 'ACCESS', username: 'alice'));

      expect(result, isA<Success<void>>());
      expect(await secure.read(idTokenKey), isNull);
      expect(await secure.read(expiryKey), isNull);
    });

    test('rolls the OIDC ID token and expiry back when a later write fails', () async {
      final failing = _WriteFailSecureStorage(failOnWrite: expiryKey);
      await failing.write(SecureStorageKeys.jwtToken.key, 'OLD_ACCESS');
      await failing.write(SecureStorageKeys.refreshToken.key, 'OLD_REFRESH');
      await failing.write(idTokenKey, 'OLD_ID_TOKEN');
      final repo = AuthSessionRepository(secureStorage: failing, storage: storage, oidcKeys: true);
      final session = AuthSession(
        idToken: 'NEW_ACCESS',
        refreshToken: 'NEW_REFRESH',
        username: 'alice',
        oidcIdToken: 'NEW_ID_TOKEN',
        accessTokenExpiresAt: expiresAt,
      );

      final result = await repo.persist(session);

      expect(result, isA<Failure<void>>());
      expect(await failing.read(SecureStorageKeys.jwtToken.key), 'OLD_ACCESS');
      expect(await failing.read(SecureStorageKeys.refreshToken.key), 'OLD_REFRESH');
      expect(await failing.read(idTokenKey), 'OLD_ID_TOKEN');
      expect(await failing.read(expiryKey), isNull, reason: 'the expiry the failed write stored is removed');
    });

    test('restores a stored expiry and ID token when a local write fails', () async {
      final priorExpiry = encodeAccessTokenExpiry(expiresAt);
      await secure.write(idTokenKey, 'OLD_ID_TOKEN');
      await secure.write(expiryKey, priorExpiry);
      final flaky = _FlakyStorage(storage, StorageKeys.username.key);
      final repo = AuthSessionRepository(secureStorage: secure, storage: flaky, oidcKeys: true);
      final session = AuthSession(
        idToken: 'NEW_ACCESS',
        username: 'bob',
        oidcIdToken: 'NEW_ID_TOKEN',
        accessTokenExpiresAt: expiresAt.add(const Duration(minutes: 5)),
      );

      final result = await repo.persist(session);

      expect(result, isA<Failure<void>>());
      expect(await secure.read(idTokenKey), 'OLD_ID_TOKEN');
      expect(await secure.read(expiryKey), priorExpiry);
    });

    test('clear deletes the OIDC ID token and the expiry', () async {
      final repo = AuthSessionRepository(secureStorage: secure, storage: storage, oidcKeys: true);
      await repo.persist(
        AuthSession(idToken: 'ACCESS', username: 'alice', oidcIdToken: 'ID_TOKEN', accessTokenExpiresAt: expiresAt),
      );

      final result = await repo.clear();

      expect(result, isA<Success<void>>());
      expect(await secure.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await secure.read(idTokenKey), isNull);
      expect(await secure.read(expiryKey), isNull);
    });

    test('clear keeps deleting the OIDC keys when the bearer delete throws', () async {
      final flaky = _SelectiveFailSecureStorage(failOn: SecureStorageKeys.jwtToken.key);
      await flaky.write(idTokenKey, 'ID_TOKEN');
      await flaky.write(expiryKey, encodeAccessTokenExpiry(expiresAt));
      final repo = AuthSessionRepository(secureStorage: flaky, storage: storage, oidcKeys: true);

      final result = await repo.clear();

      expect(result, isA<Failure<void>>());
      expect(await flaky.read(idTokenKey), isNull);
      expect(await flaky.read(expiryKey), isNull);
    });

    test('clear reports an OIDC key it cannot delete and still removes the rest', () async {
      final flaky = _SelectiveFailSecureStorage(failOn: idTokenKey);
      await flaky.write(SecureStorageKeys.jwtToken.key, 'ACCESS');
      await flaky.write(expiryKey, encodeAccessTokenExpiry(expiresAt));
      final repo = AuthSessionRepository(secureStorage: flaky, storage: storage, oidcKeys: true);

      final result = await repo.clear();

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error.message, contains('oidcIdToken'));
      expect(await flaky.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await flaky.read(expiryKey), isNull);
    });

    test('never reads, writes or deletes the OIDC keys', () async {
      final recording = _CallRecordingSecureStorage();
      final session = AuthSession(
        idToken: 'ACCESS',
        refreshToken: 'REFRESH',
        username: 'alice',
        oidcIdToken: 'ID_TOKEN',
        accessTokenExpiresAt: expiresAt,
      );

      await AuthSessionRepository(secureStorage: recording, storage: storage).persist(session);
      expect(recording.calls, [
        'read ${SecureStorageKeys.jwtToken.key}',
        'read ${SecureStorageKeys.refreshToken.key}',
        'write ${SecureStorageKeys.jwtToken.key}',
        'write ${SecureStorageKeys.refreshToken.key}',
      ]);
      // A local write that fails sends persist through the rollback.
      final flaky = _FlakyStorage(storage, StorageKeys.username.key);
      await AuthSessionRepository(secureStorage: recording, storage: flaky).persist(session);
      await AuthSessionRepository(secureStorage: recording, storage: storage).clear();

      expect(recording.calls, isNotEmpty);
      expect(recording.calls.where((call) => call.endsWith(' $idTokenKey') || call.endsWith(' $expiryKey')), isEmpty);
    });
  });

  // A logout or the end of the session wipes the stored session while requests may still get 401 and ask for a token
  // refresh. TokenRefreshInterceptor must not store the rotated tokens of a session the wipe ended, or a relaunch
  // restores it.
  group('AuthSessionRepository.clear during a token refresh', () {
    late Dio dio;
    late _RefreshStub refreshStub;
    late int sessionExpiredCalls;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))..interceptors.add(_OkStub());
      refreshStub = _RefreshStub();
      sessionExpiredCalls = 0;
    });

    tearDown(() => dio.close());

    TokenRefreshInterceptor refreshInterceptor(ISecureStorage secureStorage) => TokenRefreshInterceptor(
      dio: dio,
      secureStorage: secureStorage,
      onSessionExpired: () => sessionExpiredCalls++,
      refreshDioFactory: (source) => Dio(BaseOptions(baseUrl: source.options.baseUrl))..interceptors.add(refreshStub),
    );

    // Regression: a logout that started while the 401 read the stored token let the refresh read the refresh token
    // before the wipe deleted it, and the refresh stored the rotated tokens after the wipe, so a relaunch restored the
    // session the user ended.
    test('stores no tokens when the wipe starts while the 401 reads the stored token', () async {
      final inOrder = _InOrderSecureStorage()
        ..store[SecureStorageKeys.jwtToken.key] = 'old-jwt'
        ..store[SecureStorageKeys.refreshToken.key] = 'old-refresh';
      final sent = await _send(AuthInterceptor(secureStorage: inOrder), RequestOptions(path: '/account'));
      final unauthorized = DioException(
        requestOptions: sent,
        response: Response(requestOptions: sent, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      final handled = refreshInterceptor(inOrder).onError(unauthorized, handler);
      // The user logs out while the 401 reads the stored token.
      final cleared = AuthSessionRepository(secureStorage: inOrder, storage: storage).clear();
      await Future.wait([handled, cleared]);

      expect(inOrder.store, isEmpty, reason: 'a relaunch restores the tokens that are stored');
      expect(refreshStub.requests, 0, reason: 'the session the logout ended is not refreshed');
      expect(handler.passedOn, same(unauthorized), reason: 'the request fails with its 401');
      expect(sessionExpiredCalls, 0);
    });

    // The refresh token stored after a logout belongs to the session the user signed in to since, not to the request.
    test('does not refresh the next session for a request sent before the logout', () async {
      await secure.write(SecureStorageKeys.refreshToken.key, 'old-refresh');
      // No token is stored, so the request goes out without one.
      final sent = await _send(AuthInterceptor(secureStorage: secure), RequestOptions(path: '/account'));
      await AuthSessionRepository(secureStorage: secure, storage: storage).clear();
      await secure.write(SecureStorageKeys.jwtToken.key, 'signed-in-jwt');
      await secure.write(SecureStorageKeys.refreshToken.key, 'signed-in-refresh');
      final unauthorized = DioException(
        requestOptions: sent,
        response: Response(requestOptions: sent, statusCode: 401),
      );
      final handler = _TestErrorHandler();

      await refreshInterceptor(secure).onError(unauthorized, handler);

      expect(refreshStub.requests, 0);
      expect(handler.passedOn, same(unauthorized), reason: 'the request fails with its 401');
      expect(await secure.read(SecureStorageKeys.jwtToken.key), 'signed-in-jwt');
      expect(await secure.read(SecureStorageKeys.refreshToken.key), 'signed-in-refresh');
      expect(sessionExpiredCalls, 0);
    });

    // On web the refreshes of all browser tabs take turns at one lock. A logout must never wait behind a refresh that
    // a slow server holds it for: nothing on the wipe path takes the lock.
    test('does not make logout wait for a refresh that holds the lock', () async {
      await secure.write(SecureStorageKeys.jwtToken.key, 'old-jwt');
      await secure.write(SecureStorageKeys.refreshToken.key, 'old-refresh');
      final rotation = _HangingRotation();
      final sent = await _send(AuthInterceptor(secureStorage: secure), RequestOptions(path: '/account'));
      final unauthorized = DioException(
        requestOptions: sent,
        response: Response(requestOptions: sent, statusCode: 401),
      );
      final handled = TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secure,
        rotation: rotation,
        refreshLock: _OneAtATimeLock(),
        onSessionExpired: () => sessionExpiredCalls++,
      ).onError(unauthorized, _TestErrorHandler());
      await rotation.started.future;

      final cleared = await AuthSessionRepository(
        secureStorage: secure,
        storage: storage,
      ).clear().timeout(const Duration(seconds: 1));

      expect(cleared, isA<Success<void>>());
      expect(await secure.read(SecureStorageKeys.refreshToken.key), isNull);
      rotation.answer.complete(const RotationRefused());
      await handled;
    });
  });
}

/// In-memory ISecureStorage that records, at each call, the session generation and whether it counts as ended.
class _GenerationRecordingSecureStorage extends _MemorySecureStorage {
  final calls = <({int generation, bool ended})>[];

  void _record() {
    final generation = SessionGeneration.current;
    calls.add((generation: generation, ended: SessionGeneration.hasEnded(generation)));
  }

  @override
  Future<String?> read(String key) {
    _record();
    return super.read(key);
  }

  @override
  Future<void> write(String key, String value) {
    _record();
    return super.write(key, value);
  }

  @override
  Future<void> delete(String key) {
    _record();
    return super.delete(key);
  }
}

/// Cache that records whether the session generation counted as ended when it was cleared.
class _GenerationRecordingCacheStorage implements ICacheStorage {
  bool? endedWhenCleared;

  @override
  Future<CacheEntry?> read(String key) async => null;
  @override
  Future<void> write(String key, String data, {Duration? ttl}) async {}
  @override
  Future<void> remove(String key) async {}
  @override
  Future<void> clear() async => endedWhenCleared = SessionGeneration.hasEnded(SessionGeneration.current);
}

/// ISecureStorage that answers like the platform store: each call takes effect when it is made, and the answers come
/// back in the order of the calls, each a moment after the one before.
class _InOrderSecureStorage implements ISecureStorage {
  final store = <String, String>{};
  Future<void> _lastAnswer = Future<void>.value();

  Future<T> _answer<T>(T value) {
    final answer = _lastAnswer.then((_) => Future<void>.delayed(const Duration(milliseconds: 1)));
    _lastAnswer = answer;
    return answer.then((_) => value);
  }

  @override
  Future<String?> read(String key) => _answer(store[key]);

  @override
  Future<void> write(String key, String value) {
    store[key] = value;
    return _answer<void>(null);
  }

  @override
  Future<void> delete(String key) {
    store.remove(key);
    return _answer<void>(null);
  }

  @override
  Future<void> deleteAll() {
    store.clear();
    return _answer<void>(null);
  }
}

/// Sends [options] through [interceptor], as the client sends every request, and returns them as they leave it.
Future<RequestOptions> _send(AuthInterceptor interceptor, RequestOptions options) async {
  final handler = _TestRequestHandler();
  await interceptor.onRequest(options, handler);
  return handler.sent!;
}

class _TestRequestHandler extends RequestInterceptorHandler {
  RequestOptions? sent;

  @override
  void next(RequestOptions requestOptions) => sent = requestOptions;
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  DioException? passedOn;

  @override
  void next(DioException err) => passedOn = err;

  @override
  void resolve(Response<dynamic> response) {}

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {}
}

/// Answers the token refresh with rotated tokens and counts the refresh requests.
class _RefreshStub extends Interceptor {
  int requests = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests++;
    handler.resolve(
      Response(requestOptions: options, statusCode: 200, data: '{"id_token":"new-jwt","refresh_token":"new-refresh"}'),
    );
  }
}

/// Answers every request with 200, as the server answers a request sent again with a fresh token.
class _OkStub extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) =>
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: '{}'));
}

/// A rotation whose server takes the refresh token and answers only when the test completes [answer].
class _HangingRotation implements TokenRotation {
  final started = Completer<void>();
  final answer = Completer<TokenRotationResult>();

  @override
  Future<TokenRotationResult> rotate(String refreshToken) {
    started.complete();
    return answer.future;
  }
}

/// An [ITokenRefreshLock] that runs its holders one at a time, as the Web Lock of the browser tabs does.
class _OneAtATimeLock implements ITokenRefreshLock {
  Future<void> _tail = Future<void>.value();

  @override
  Future<T> hold<T>(Future<T> Function() body) {
    final previous = _tail;
    final released = Completer<void>();
    _tail = released.future;
    return previous.then((_) => body().whenComplete(released.complete));
  }
}
