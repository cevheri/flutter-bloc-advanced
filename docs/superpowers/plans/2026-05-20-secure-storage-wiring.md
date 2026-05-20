# SecureStorage Wiring + JWT Masking — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist JWT and refresh token through `flutter_secure_storage` instead of plaintext SharedPreferences, add structural log masking for tokens, and migrate existing installations without forcing logout.

**Architecture:** Split `StorageKeys` into a `SecureStorageKeys` enum (jwtToken, refreshToken) and a `StorageKeys` enum (username, roles, language, theme, brightness). `AuthSessionRepository` accepts both backends and performs cross-backend atomic-write rollback. `SessionMigration` runs once at bootstrap to copy legacy values from SharedPreferences to SecureStorage. `LogSanitizer.maskToken` is used at log sites and overridden in `AuthSession.toString()` so the JWT is structurally unloggable.

**Tech Stack:** Flutter 3.44 · Dart 3.x · `flutter_secure_storage` · `shared_preferences` · `dio` · `flutter_test` · `mocktail`

**Spec:** `docs/superpowers/specs/2026-05-20-secure-storage-wiring-design.md`
**Issue:** [#129](https://github.com/cevheri/flutter_bloc_advance/issues/129)
**Branch:** `feat/129-secure-storage-wiring` (already created)

> **Historical note — superseded by shipped architecture.** This plan
> was written before PR review revealed that caching the JWT in
> `AppLocalStorageCached.jwtToken` (Tasks 7 and 8) forces six
> coordinated write paths to stay in sync (persist, refresh, logout,
> rollback, clear, bootstrap) — each a potential stale-token bug. The
> shipped implementation removes the JWT cache entirely:
>
> - `AuthInterceptor` reads JWT directly from `ISecureStorage` on every
>   request — no cache, no fallback.
> - `SessionCubit.restore` reads from `ISecureStorage`, runs the pure
>   `SecurityUtils.hasToken` / `isTokenExpired` checks, and emits the
>   derived `isAuthenticated` boolean (which is the sync state UI/router
>   consumers read).
> - Repository, refresh interceptor, and logout no longer mutate any
>   cache field.
>
> Tasks 7 (cache loadCache from SecureStorage) and 8 (AuthInterceptor
> reads cached field) below describe a design that was not shipped. Tasks
> 1-6 and 9-13 still match the codebase; see the spec doc for the final
> architecture.

---

## Task 1: `LogSanitizer.maskToken` utility

**Files:**
- Create: `lib/core/logging/log_sanitizer.dart`
- Create: `test/core/logging/log_sanitizer_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/logging/log_sanitizer_test.dart
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogSanitizer.maskToken', () {
    test('returns <empty> for null', () {
      expect(LogSanitizer.maskToken(null), '<empty>');
    });

    test('returns <empty> for empty string', () {
      expect(LogSanitizer.maskToken(''), '<empty>');
    });

    test('returns <redacted> for tokens shorter than 8 chars', () {
      expect(LogSanitizer.maskToken('a'), '<redacted>');
      expect(LogSanitizer.maskToken('1234567'), '<redacted>');
    });

    test('masks the middle of an 8-char token', () {
      expect(LogSanitizer.maskToken('12345678'), '1234…5678');
    });

    test('masks a realistic JWT', () {
      const jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature';
      final masked = LogSanitizer.maskToken(jwt);
      expect(masked, startsWith('eyJh'));
      expect(masked, endsWith('ture'));
      expect(masked.contains('payload'), isFalse);
      expect(masked.contains('signature'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
fvm flutter test test/core/logging/log_sanitizer_test.dart
```

Expected: FAIL with "Target of URI doesn't exist: 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart'".

- [ ] **Step 3: Implement `LogSanitizer`**

```dart
// lib/core/logging/log_sanitizer.dart

/// Utilities for sanitizing sensitive values before they reach a log sink.
class LogSanitizer {
  /// Returns a redacted preview of a token suitable for logs.
  ///
  /// - `null` or empty → `<empty>`
  /// - shorter than 8 characters → `<redacted>`
  /// - otherwise → `XXXX…YYYY` (first 4 + last 4)
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) return '<empty>';
    if (token.length < 8) return '<redacted>';
    return '${token.substring(0, 4)}…${token.substring(token.length - 4)}';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
fvm flutter test test/core/logging/log_sanitizer_test.dart
```

Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/logging/log_sanitizer.dart test/core/logging/log_sanitizer_test.dart
git commit -m "feat(#129): add LogSanitizer.maskToken helper"
```

---

## Task 2: `AuthSession.toString()` override

**Files:**
- Modify: `lib/features/auth/domain/entities/auth_session.dart`
- Create: `test/features/auth/domain/entities/auth_session_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/domain/entities/auth_session_test.dart
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession.toString', () {
    test('masks idToken and refreshToken', () {
      const session = AuthSession(
        idToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature',
        refreshToken: 'refresh-token-value-12345',
        username: 'alice',
        roles: ['ROLE_USER'],
      );

      final rendered = session.toString();

      expect(rendered.contains('payload'), isFalse);
      expect(rendered.contains('refresh-token-value-12345'), isFalse);
      expect(rendered, contains('alice'));
      expect(rendered, contains('ROLE_USER'));
    });

    test('renders empty marker when refreshToken is null', () {
      const session = AuthSession(idToken: 'eyJhbGc.payload.signature', username: 'alice');
      expect(session.toString(), contains('refreshToken: <empty>'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
fvm flutter test test/features/auth/domain/entities/auth_session_test.dart
```

Expected: FAIL — default `toString()` exposes raw token values.

- [ ] **Step 3: Add `toString()` override**

Modify `lib/features/auth/domain/entities/auth_session.dart`. Add the import and override:

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';

/// Value object representing a fully-formed authenticated session.
/// ... (existing docstring unchanged)
class AuthSession extends Equatable {
  const AuthSession({required this.idToken, required this.username, this.refreshToken, this.roles = const []})
    : assert(idToken != '', 'idToken must be non-empty');

  final String idToken;
  final String? refreshToken;
  final String username;
  final List<String> roles;

  @override
  List<Object?> get props => [idToken, refreshToken, username, roles];

  /// Tokens are masked so this is safe to embed in log output, even if
  /// `Equatable.stringify` is later flipped on for diagnostic reasons.
  @override
  String toString() => 'AuthSession('
      'idToken: ${LogSanitizer.maskToken(idToken)}, '
      'refreshToken: ${LogSanitizer.maskToken(refreshToken)}, '
      'username: $username, '
      'roles: $roles)';
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
fvm flutter test test/features/auth/domain/entities/auth_session_test.dart
```

Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/domain/entities/auth_session.dart test/features/auth/domain/entities/auth_session_test.dart
git commit -m "feat(#129): mask tokens in AuthSession.toString()"
```

---

## Task 3: Split `StorageKeys` — introduce `SecureStorageKeys`

**Files:**
- Modify: `lib/infrastructure/storage/secure_storage.dart` (add enum)
- Modify: `lib/infrastructure/storage/local_storage.dart` (remove `jwtToken` and `refreshToken` from `StorageKeys`)

> **Note:** This task intentionally breaks compilation for callers that still reference `StorageKeys.jwtToken` / `StorageKeys.refreshToken`. Subsequent tasks (4–12) repair each call site. Run `fvm dart analyze` after each subsequent task; the error list shrinks until it's empty after Task 12.

- [ ] **Step 1: Add `SecureStorageKeys` enum to `secure_storage.dart`**

Insert at the bottom of `lib/infrastructure/storage/secure_storage.dart` (after `FlutterSecureStorageAdapter`):

```dart
/// Keys for values that must be stored in the platform-backed secure
/// store (iOS Keychain, Android EncryptedSharedPreferences).
///
/// Renaming an enum value will NOT change the stored key, so user data
/// survives refactors safely. Add new entries by appending — do not
/// change existing [key] strings without a migration.
enum SecureStorageKeys {
  jwtToken('jwtToken'),
  refreshToken('refreshToken');

  const SecureStorageKeys(this.key);

  final String key;
}
```

- [ ] **Step 2: Remove `jwtToken` and `refreshToken` from `StorageKeys`**

Modify `lib/infrastructure/storage/local_storage.dart`:

```dart
enum StorageKeys {
  roles('roles'),
  language('language'),
  username('username'),
  theme('theme'),
  brightness('brightness');

  const StorageKeys(this.key);

  final String key;
}
```

- [ ] **Step 3: Verify the analyzer surfaces the expected breaks**

```bash
fvm dart analyze
```

Expected: errors at the call sites we will repair in Tasks 4, 8, 9, 10, 12 (e.g. `auth_session_repository_impl.dart`, `auth_interceptor.dart`, `token_refresh_interceptor.dart`, `local_storage.dart:16`, test files). The exact count is informational — we just need to confirm the breaks are localized.

- [ ] **Step 4: Commit (does not build green yet; that is intentional)**

```bash
git add lib/infrastructure/storage/secure_storage.dart lib/infrastructure/storage/local_storage.dart
git commit -m "refactor(#129): split SecureStorageKeys from StorageKeys"
```

---

## Task 4: Wire `ISecureStorage` into `AppDependencies` and `AppScope`

**Files:**
- Modify: `lib/app/di/app_dependencies.dart`
- Modify: `lib/app/di/app_scope.dart`

- [ ] **Step 1: Add factory to `AppDependencies`**

Modify `lib/app/di/app_dependencies.dart`. Add the import and method:

```dart
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

// inside class AppDependencies, alphabetical-ish ordering with the others:
ISecureStorage createSecureStorage() => FlutterSecureStorageAdapter();
```

- [ ] **Step 2: Expose via `AppScope` as a `RepositoryProvider`**

Modify `lib/app/di/app_scope.dart`. Add the import and provider:

```dart
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

// inside MultiRepositoryProvider.providers list, near the top:
RepositoryProvider<ISecureStorage>(create: (_) => dependencies.createSecureStorage()),
```

- [ ] **Step 3: Run analyzer**

```bash
fvm dart analyze lib/app/di/
```

Expected: no new errors in the DI files.

- [ ] **Step 4: Commit**

```bash
git add lib/app/di/app_dependencies.dart lib/app/di/app_scope.dart
git commit -m "feat(#129): expose ISecureStorage through AppDependencies and AppScope"
```

---

## Task 5: `AuthSessionRepository` — cross-backend persist + rollback

**Files:**
- Modify: `lib/features/auth/data/repositories/auth_session_repository_impl.dart`
- Modify: `lib/app/di/app_dependencies.dart` (update `createAuthSessionRepository` to inject secure storage)
- Modify: `lib/app/di/app_scope.dart` (read `ISecureStorage` from context when creating repo)
- Modify: `test/features/auth/data/repositories/auth_session_repository_impl_test.dart`

- [ ] **Step 1: Replace repository test with cross-backend version**

Overwrite `test/features/auth/data/repositories/auth_session_repository_impl_test.dart` with:

```dart
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../test_utils.dart';

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

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = AppLocalStorage();
    storage.setPreferencesInstance(await SharedPreferences.getInstance());
    secure = _MemorySecureStorage();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
fvm flutter test test/features/auth/data/repositories/auth_session_repository_impl_test.dart
```

Expected: FAIL — constructor signature, persist routing, and `clear` cross-backend behavior are not yet implemented.

- [ ] **Step 3: Rewrite the repository**

Replace `lib/features/auth/data/repositories/auth_session_repository_impl.dart`:

```dart
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// Persistence-layer implementation of [IAuthSessionRepository].
///
/// Routes sensitive fields (idToken, refreshToken) to [ISecureStorage]
/// (Keychain / EncryptedSharedPreferences) and non-secret fields
/// (username, roles) to [AppLocalStorage] (SharedPreferences).
///
/// Neither backend supports transactions, so atomicity is emulated
/// across both: writes happen in order, and on any failure the keys
/// that were successfully written during this call are removed —
/// across both backends — before the failure is reported. The caller
/// therefore never sees a half-written session.
class AuthSessionRepository implements IAuthSessionRepository {
  AuthSessionRepository({required ISecureStorage secureStorage, AppLocalStorage? storage})
      : _secureStorage = secureStorage,
        _storage = storage ?? AppLocalStorage();

  static final _log = AppLogger.getLogger('AuthSessionRepository');

  final ISecureStorage _secureStorage;
  final AppLocalStorage _storage;

  @override
  Future<Result<void>> persist(AuthSession session) async {
    final writtenSecure = <SecureStorageKeys>[];
    final writtenLocal = <StorageKeys>[];
    try {
      await _writeSecure(SecureStorageKeys.jwtToken, session.idToken, writtenSecure);
      if (session.refreshToken != null) {
        await _writeSecure(SecureStorageKeys.refreshToken, session.refreshToken!, writtenSecure);
      } else {
        // Owner-of-keys contract: a session without a refresh token must
        // not inherit one from a previous login. Best-effort removal.
        await _secureStorage.delete(SecureStorageKeys.refreshToken.key);
      }
      await _writeLocal(StorageKeys.username, session.username, writtenLocal);
      await _writeLocal(StorageKeys.roles, session.roles, writtenLocal);
      return const Success(null);
    } catch (e) {
      _log.error('persist failed after {} secure + {} local writes; rolling back: {}',
                 [writtenSecure.length, writtenLocal.length, e]);
      await _rollback(writtenSecure, writtenLocal);
      return Failure(UnknownError('Session persistence failed: $e'));
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _secureStorage.delete(SecureStorageKeys.jwtToken.key);
      await _secureStorage.delete(SecureStorageKeys.refreshToken.key);
      await _storage.clear();
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError('Session clear failed: $e'));
    }
  }

  Future<void> _writeSecure(SecureStorageKeys key, String value, List<SecureStorageKeys> written) async {
    await _secureStorage.write(key.key, value);
    written.add(key);
  }

  Future<void> _writeLocal(StorageKeys key, dynamic value, List<StorageKeys> written) async {
    final ok = await _storage.save(key.key, value);
    if (!ok) {
      throw StateError('save returned false for ${key.key}');
    }
    written.add(key);
  }

  Future<void> _rollback(List<SecureStorageKeys> writtenSecure, List<StorageKeys> writtenLocal) async {
    for (final key in writtenSecure) {
      try {
        await _secureStorage.delete(key.key);
      } catch (e) {
        _log.warn('secure rollback failed for {}: {}', [key.key, e]);
      }
    }
    for (final key in writtenLocal) {
      try {
        await _storage.remove(key.key);
      } catch (e) {
        _log.warn('local rollback failed for {}: {}', [key.key, e]);
      }
    }
  }
}
```

- [ ] **Step 4: Update DI factory to inject secure storage**

In `lib/app/di/app_dependencies.dart`, change the factory to accept the dependency:

```dart
IAuthSessionRepository createAuthSessionRepository(ISecureStorage secureStorage) =>
    AuthSessionRepository(secureStorage: secureStorage);
```

In `lib/app/di/app_scope.dart`, update the `RepositoryProvider`:

```dart
RepositoryProvider<IAuthSessionRepository>(
  create: (context) => dependencies.createAuthSessionRepository(context.read<ISecureStorage>()),
),
```

The `ISecureStorage` provider added in Task 4 must appear **before** this one in the `providers` list so that `context.read<ISecureStorage>()` resolves.

- [ ] **Step 5: Run tests to verify they pass**

```bash
fvm flutter test test/features/auth/data/repositories/auth_session_repository_impl_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/data/repositories/auth_session_repository_impl.dart \
        lib/app/di/app_dependencies.dart lib/app/di/app_scope.dart \
        test/features/auth/data/repositories/auth_session_repository_impl_test.dart
git commit -m "feat(#129): route tokens through ISecureStorage in AuthSessionRepository"
```

---

## Task 6: `SessionMigration` — one-shot bootstrap migration

**Files:**
- Create: `lib/infrastructure/storage/session_migration.dart`
- Create: `test/infrastructure/storage/session_migration_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/infrastructure/storage/session_migration_test.dart
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_utils.dart';

class _MemorySecureStorage implements ISecureStorage {
  _MemorySecureStorage({this.failOnWrite = false});
  final Map<String, String> _store = {};
  final bool failOnWrite;
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async {
    if (failOnWrite) throw StateError('boom');
    _store[key] = value;
  }
  @override
  Future<void> delete(String key) async => _store.remove(key);
  @override
  Future<void> deleteAll() async => _store.clear();
}

void main() {
  late AppLocalStorage local;
  late _MemorySecureStorage secure;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = AppLocalStorage();
    local.setPreferencesInstance(await SharedPreferences.getInstance());
    secure = _MemorySecureStorage();
  });

  tearDown(() async => TestUtils().tearDownUnitTest());

  group('SessionMigration.run', () {
    test('migrates jwtToken and refreshToken from local to secure', () async {
      await local.save('jwtToken', 'JWT_VALUE');
      await local.save('refreshToken', 'REFRESH_VALUE');

      await SessionMigration.run(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), 'JWT_VALUE');
      expect(await secure.read('refreshToken'), 'REFRESH_VALUE');
      expect(await local.read('jwtToken'), isNull);
      expect(await local.read('refreshToken'), isNull);
    });

    test('is a no-op when secure storage already has the value (idempotent)', () async {
      await secure.write('jwtToken', 'ALREADY_MIGRATED');
      await local.save('jwtToken', 'STALE');

      await SessionMigration.run(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), 'ALREADY_MIGRATED');
      // Legacy value was not removed because migration did not run.
      expect(await local.read('jwtToken'), 'STALE');
    });

    test('is a no-op when there is nothing to migrate', () async {
      await SessionMigration.run(secureStorage: secure, localStorage: local);

      expect(await secure.read('jwtToken'), isNull);
      expect(await secure.read('refreshToken'), isNull);
    });

    test('does not throw when secure write fails', () async {
      final flaky = _MemorySecureStorage(failOnWrite: true);
      await local.save('jwtToken', 'JWT_VALUE');

      await SessionMigration.run(secureStorage: flaky, localStorage: local);

      // Legacy value still present — best-effort semantics.
      expect(await local.read('jwtToken'), 'JWT_VALUE');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
fvm flutter test test/infrastructure/storage/session_migration_test.dart
```

Expected: FAIL — `package:flutter_bloc_advance/infrastructure/storage/session_migration.dart` does not exist.

- [ ] **Step 3: Implement `SessionMigration`**

```dart
// lib/infrastructure/storage/session_migration.dart
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// One-shot migration from plaintext SharedPreferences to SecureStorage.
///
/// Runs at bootstrap before [AppLocalStorageCached.loadCache] so the
/// cache sees the post-migration state. Idempotent: any value already
/// present in [ISecureStorage] is left alone. Best-effort: a failure
/// logs a warning and returns; worst case the user re-authenticates
/// on the next launch.
class SessionMigration {
  static final _log = AppLogger.getLogger('SessionMigration');

  // Legacy SharedPreferences keys — referenced as literals because the
  // corresponding StorageKeys entries were removed in Task 3.
  static const _legacyKeys = <String>['jwtToken', 'refreshToken'];

  static Future<void> run({
    required ISecureStorage secureStorage,
    required AppLocalStorage localStorage,
  }) async {
    for (final legacyKey in _legacyKeys) {
      await _migrateOne(legacyKey, secureStorage, localStorage);
    }
  }

  static Future<void> _migrateOne(
    String legacyKey,
    ISecureStorage secureStorage,
    AppLocalStorage localStorage,
  ) async {
    try {
      final existing = await secureStorage.read(legacyKey);
      if (existing != null && existing.isNotEmpty) return; // already migrated

      final legacy = await localStorage.read(legacyKey);
      if (legacy is! String || legacy.isEmpty) return; // nothing to migrate

      await secureStorage.write(legacyKey, legacy);
      await localStorage.remove(legacyKey);
      _log.info('Migrated {} from SharedPreferences to SecureStorage', [legacyKey]);
    } catch (e) {
      _log.warn('Migration failed for {}: {}', [legacyKey, e]);
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
fvm flutter test test/infrastructure/storage/session_migration_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/infrastructure/storage/session_migration.dart test/infrastructure/storage/session_migration_test.dart
git commit -m "feat(#129): add SessionMigration for one-shot bootstrap copy"
```

---

## Task 7: `AppLocalStorageCached.loadCache` reads JWT from SecureStorage

**Files:**
- Modify: `lib/infrastructure/storage/local_storage.dart`

- [ ] **Step 1: Update `loadCache` signature**

In `lib/infrastructure/storage/local_storage.dart`, modify `AppLocalStorageCached`:

```dart
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

class AppLocalStorageCached {
  static final _log = AppLogger.getLogger("AppLocalStorageCached");
  static late String? jwtToken;
  static late List<String>? roles;
  static late String? language;
  static late String? username;
  static late String? theme;
  static late String? brightness;

  static Future<void> loadCache({ISecureStorage? secureStorage}) async {
    _log.trace("Loading cache");
    final secure = secureStorage ?? FlutterSecureStorageAdapter();
    jwtToken = await secure.read(SecureStorageKeys.jwtToken.key);
    roles = await AppLocalStorage().read(StorageKeys.roles.key);
    language = await AppLocalStorage().read(StorageKeys.language.key) ?? "en";
    username = await AppLocalStorage().read(StorageKeys.username.key);
    theme = await AppLocalStorage().read(StorageKeys.theme.key) ?? "classic";
    brightness = await AppLocalStorage().read(StorageKeys.brightness.key) ?? "light";
    _log.trace("Loaded cache with username:{}, roles:{}, language:{}, jwtToken-present:{}, theme:{}, brightness:{}", [
      username,
      roles,
      language,
      jwtToken != null,
      theme,
      brightness,
    ]);
  }
}
```

The trace log no longer prints the JWT value itself; we already mask elsewhere but the cache layer should not leak the raw token through trace logs either.

- [ ] **Step 2: Run analyzer**

```bash
fvm dart analyze lib/infrastructure/storage/local_storage.dart
```

Expected: no errors in this file. (Errors at the existing `AppLocalStorage().save/remove` paths that internally call `loadCache()` should now resolve correctly since the new signature has an optional parameter.)

- [ ] **Step 3: Commit**

```bash
git add lib/infrastructure/storage/local_storage.dart
git commit -m "feat(#129): cache layer reads jwtToken from SecureStorage"
```

---

## Task 8: `AuthInterceptor` — read JWT from cache (no enum dependency)

**Files:**
- Modify: `lib/infrastructure/http/interceptors/auth_interceptor.dart`

- [ ] **Step 1: Replace the interceptor implementation**

```dart
// lib/infrastructure/http/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

/// Injects JWT Bearer token into every outgoing request.
///
/// Reads from the in-memory cache rather than disk because this runs
/// on every HTTP request and the cache is kept fresh by the persist /
/// refresh / clear paths.
class AuthInterceptor extends Interceptor {
  static final _log = AppLogger.getLogger('AuthInterceptor');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final jwtToken = AppLocalStorageCached.jwtToken;
    if (jwtToken != null && jwtToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $jwtToken';
    }
    _log.debug('Request [{}] {} (auth: {})', [options.method, options.path, jwtToken != null]);
    handler.next(options);
  }
}
```

(Method signature changes from `Future<void>` to `void` because we no longer await disk I/O. `Interceptor.onRequest` allows both.)

- [ ] **Step 2: Run analyzer**

```bash
fvm dart analyze lib/infrastructure/http/interceptors/auth_interceptor.dart
```

Expected: no errors.

- [ ] **Step 3: Run existing AuthInterceptor tests (if any) to confirm they still pass**

```bash
fvm flutter test test/infrastructure/http/interceptors/
```

Expected: TokenRefreshInterceptor tests still fail (we fix in Task 9), but the AuthInterceptor file compiles. If there is a specific AuthInterceptor test, it may need a `AppLocalStorageCached.jwtToken = '...'` setup line — fix inline if so.

- [ ] **Step 4: Commit**

```bash
git add lib/infrastructure/http/interceptors/auth_interceptor.dart
git commit -m "refactor(#129): AuthInterceptor reads JWT from cached field"
```

---

## Task 9: `TokenRefreshInterceptor` + `ApiClient` use `ISecureStorage`

**Files:**
- Modify: `lib/infrastructure/http/interceptors/token_refresh_interceptor.dart`
- Modify: `lib/infrastructure/http/api_client.dart`
- Modify: `test/infrastructure/http/interceptors/token_refresh_interceptor_test.dart`

- [ ] **Step 1: Add a static `secureStorage` field on `ApiClient`**

In `lib/infrastructure/http/api_client.dart`, near `static OnSessionExpired? onSessionExpired;`:

```dart
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

// ...
static OnSessionExpired? onSessionExpired;

/// Secure storage used by the token-refresh interceptor.
///
/// Set this before the first API call (typically in app bootstrap).
/// Falls back to a fresh [FlutterSecureStorageAdapter] if unset, so
/// tests don't need to wire it up.
static ISecureStorage? secureStorage;
```

Then in `_createDio()`, where `TokenRefreshInterceptor` is constructed:

```dart
(
  interceptor: TokenRefreshInterceptor(
    dio: dio,
    secureStorage: secureStorage ?? FlutterSecureStorageAdapter(),
    onSessionExpired: onSessionExpired,
  ),
  meta: const InterceptorChainEntry(name: 'TokenRefreshInterceptor', detail: 'Refreshes expired access tokens'),
),
```

- [ ] **Step 2: Rewrite the interceptor**

Replace `lib/infrastructure/http/interceptors/token_refresh_interceptor.dart`:

```dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

typedef OnSessionExpired = void Function();

/// Intercepts 401 responses and attempts a silent token refresh.
///
/// Tokens are read from and written to [ISecureStorage]. After a
/// successful refresh the in-memory cache is reloaded so that
/// downstream consumers (`AuthInterceptor`, `SecurityUtils`) see the
/// rotated JWT immediately.
class TokenRefreshInterceptor extends QueuedInterceptor {
  static final _log = AppLogger.getLogger('TokenRefreshInterceptor');

  final Dio _dio;
  final ISecureStorage _secureStorage;
  final OnSessionExpired? _onSessionExpired;

  TokenRefreshInterceptor({
    required Dio dio,
    required ISecureStorage secureStorage,
    OnSessionExpired? onSessionExpired,
  })  : _dio = dio,
        _secureStorage = secureStorage,
        _onSessionExpired = onSessionExpired;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final requestPath = err.requestOptions.path;
    if (requestPath.contains('/api/token/refresh')) {
      _log.warn('Refresh endpoint returned 401 — session expired');
      _triggerLogout();
      handler.next(err);
      return;
    }

    _log.debug('401 received for {} — attempting token refresh', [requestPath]);

    try {
      final refreshToken = await _secureStorage.read(SecureStorageKeys.refreshToken.key);
      if (refreshToken == null || refreshToken.isEmpty) {
        _log.warn('No refresh token available — session expired');
        _triggerLogout();
        handler.next(err);
        return;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post('/api/token/refresh', data: jsonEncode({'refresh_token': refreshToken}));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is String ? jsonDecode(response.data as String) : response.data;

        final newIdToken = data['id_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newIdToken == null || newIdToken.isEmpty) {
          _log.error('Refresh response missing id_token — session expired');
          _triggerLogout();
          handler.next(err);
          return;
        }

        await _secureStorage.write(SecureStorageKeys.jwtToken.key, newIdToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _secureStorage.write(SecureStorageKeys.refreshToken.key, newRefreshToken);
        }
        // Refresh the in-memory cache so AuthInterceptor and SecurityUtils
        // observe the rotated token immediately.
        await AppLocalStorageCached.loadCache(secureStorage: _secureStorage);

        _log.info('Token refresh successful — retrying original request');

        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newIdToken';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
        return;
      }

      _log.warn('Refresh endpoint returned {} — session expired', [response.statusCode]);
      _triggerLogout();
      handler.next(err);
    } catch (e) {
      _log.error('Refresh attempt threw: {}', [e]);
      _triggerLogout();
      handler.next(err);
    }
  }

  void _triggerLogout() {
    if (_onSessionExpired != null) {
      _log.info('Notifying app layer of session expiry');
      _onSessionExpired();
    }
  }
}
```

- [ ] **Step 3: Update existing interceptor tests**

In `test/infrastructure/http/interceptors/token_refresh_interceptor_test.dart`:

1. Add an in-memory `_MemorySecureStorage` (identical to the one used in the repository test — copy/paste, no shared util yet).
2. Update every `TokenRefreshInterceptor(dio: dio, ...)` call to pass `secureStorage: secure,` where `secure` is a `_MemorySecureStorage()` instance set up in `setUp`.
3. Replace `await localStorage.save(StorageKeys.refreshToken.key, ...)` with `await secure.write(SecureStorageKeys.refreshToken.key, ...)`.
4. Replace `await localStorage.save(StorageKeys.jwtToken.key, ...)` with `await secure.write(SecureStorageKeys.jwtToken.key, ...)`.
5. For any assertion that checks the rotated tokens were persisted, read from `secure.read(SecureStorageKeys.jwtToken.key)` / `SecureStorageKeys.refreshToken.key` instead of `AppLocalStorage().read(StorageKeys.jwtToken.key)`.

The file already has its own structure — keep tests organized as they are, just change the source of truth.

- [ ] **Step 4: Run interceptor tests**

```bash
fvm flutter test test/infrastructure/http/interceptors/token_refresh_interceptor_test.dart
```

Expected: PASS (all existing assertions).

- [ ] **Step 5: Commit**

```bash
git add lib/infrastructure/http/interceptors/token_refresh_interceptor.dart \
        lib/infrastructure/http/api_client.dart \
        test/infrastructure/http/interceptors/token_refresh_interceptor_test.dart
git commit -m "feat(#129): TokenRefreshInterceptor uses ISecureStorage; refreshes cache"
```

---

## Task 10: Bootstrap wires `ISecureStorage`, runs migration, refreshes cache

**Files:**
- Modify: `lib/app/bootstrap/app_bootstrap.dart`

- [ ] **Step 1: Add wiring**

In `lib/app/bootstrap/app_bootstrap.dart`, modify the `run` method:

```dart
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_migration.dart';

// ...

class AppBootstrap {
  static Future<void> run(AppBootstrapConfig config) async {
    WidgetsFlutterBinding.ensureInitialized();

    await AppConstants.initPackageInfo();

    AppLogger.configure(isProduction: config.isProduction);
    final log = AppLogger.getLogger('AppBootstrap');

    ProfileConstants.setEnvironment(config.environment);

    final dependencies = AppDependencies(environment: config.environment);
    final secureStorage = dependencies.createSecureStorage();
    ApiClient.secureStorage = secureStorage; // available to TokenRefreshInterceptor

    // One-shot migration of legacy plaintext tokens. Must run BEFORE
    // AppLocalStorageCached.loadCache so the cache sees the post-
    // migration state.
    await SessionMigration.run(secureStorage: secureStorage, localStorage: AppLocalStorage());

    final existingLang = await AppLocalStorage().read(StorageKeys.language.key);
    if (existingLang == null) {
      await AppLocalStorage().save(StorageKeys.language.key, config.defaultLanguage);
    }
    final existingPalette = await AppLocalStorage().read(StorageKeys.theme.key);
    if (existingPalette == null) {
      await AppLocalStorage().save(StorageKeys.theme.key, config.defaultPalette);
    }
    await AppLocalStorageCached.loadCache(secureStorage: secureStorage);

    await ConnectivityService.instance.initialize();

    final analytics = LogAnalyticsService();
    CrashReporter.install(analytics);

    Bloc.observer = kDebugMode ? TimeTravelBlocObserver() : AppBlocObserver();

    AppRouter().setRouter(RouterType.goRouter);

    await SystemChrome.setPreferredOrientations(config.preferredOrientations);

    log.info('Starting app with env: {}, language: {}, palette: {}, brightness: {}', [
      config.environment.name,
      config.defaultLanguage,
      config.defaultPalette,
      config.defaultBrightness,
    ]);

    runApp(
      App(
        language: config.defaultLanguage,
        dependencies: dependencies,
        analytics: analytics,
      ),
    );
  }
}
```

(The previous code constructed `AppDependencies` inside `runApp` — we lift it earlier so we can pass the same secure storage instance to `ApiClient`, `SessionMigration`, and the widget tree.)

- [ ] **Step 2: Run analyzer**

```bash
fvm dart analyze lib/app/bootstrap/
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/app/bootstrap/app_bootstrap.dart
git commit -m "feat(#129): bootstrap wires SecureStorage and runs SessionMigration"
```

---

## Task 11: Sanitize `login_bloc.dart:140`

**Files:**
- Modify: `lib/features/auth/application/login_bloc.dart` (line 140)

**Context:** `data` in this scope is an `AuthTokenEntity` (return value of `_verifyOtpUseCase`). The entity exposes a nullable `idToken: String?`. Cache refresh after persist is handled implicitly: `AuthSessionRepository.persist` writes username via `AppLocalStorage.save`, which already calls `AppLocalStorageCached.loadCache()` — and after Task 7 that cache load reads the just-written JWT from secure storage.

- [ ] **Step 1: Add the import**

At the top of `lib/features/auth/application/login_bloc.dart`:

```dart
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
```

- [ ] **Step 2: Sanitize line 140**

Replace:

```dart
_log.debug("onVerifyOtpSubmitted token: {}", [data.toString()]);
```

With:

```dart
_log.debug("onVerifyOtpSubmitted token: {}", [LogSanitizer.maskToken(data.idToken)]);
```

(`data` is non-null here — it came from the `Success(:final data)` pattern match — but `data.idToken` is nullable. `maskToken` handles null cleanly.)

- [ ] **Step 3: Run login BLoC tests**

```bash
fvm flutter test test/features/auth/application/login_bloc_test.dart
```

Expected: PASS. If a test asserts on the previous debug message text containing a raw token, update it to expect the masked form (`'1234…5678'` shape) — fix inline.

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/application/login_bloc.dart
git commit -m "feat(#129): sanitize login OTP debug log with LogSanitizer"
```

---

## Task 12: Repair existing tests that reference removed enum values

**Files (test-only updates):**
- Modify: `test/test_utils.dart`
- Modify: `test/features/auth/data/repositories/login_repository_test.dart`
- Modify: `test/app/session/session_cubit_test.dart`
- Modify: `test/features/auth/presentation/widgets/login_otp_verify_widget_test.dart`
- Modify: `test/features/auth/application/login_bloc_test.dart`
- Modify: `test/core/security/security_utils_test.dart`

> **Goal:** (1) Mock the `flutter_secure_storage` MethodChannel globally so `AppLocalStorageCached.loadCache()` works in tests. (2) Replace every remaining reference to `StorageKeys.jwtToken` and `StorageKeys.refreshToken` (which no longer exist) with the equivalent secure-storage or cache-field setup. After this task the analyzer is clean and the full test suite is green.

- [ ] **Step 1: Add a MethodChannel mock to `test_utils.dart`**

`AppLocalStorage.save/remove/clear` internally call `AppLocalStorageCached.loadCache()`, which now reads `SecureStorageKeys.jwtToken` via `flutter_secure_storage`. Without a mock that channel throws `MissingPluginException` in tests.

In `test/test_utils.dart`, add:

```dart
import 'package:flutter/services.dart';

class TestUtils {
  /// In-memory backing store for the mocked flutter_secure_storage channel.
  static final Map<String, String> _secureStore = {};

  static const _secureChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  static void _installSecureStorageMock() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureChannel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? const {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return _secureStore[key];
        case 'readAll':
          return Map<String, String>.from(_secureStore);
        case 'write':
          _secureStore[key!] = args['value'] as String;
          return null;
        case 'delete':
          _secureStore.remove(key);
          return null;
        case 'deleteAll':
          _secureStore.clear();
          return null;
        case 'containsKey':
          return _secureStore.containsKey(key);
        default:
          return null;
      }
    });
  }
  // ...
}
```

Then call `_installSecureStorageMock()` once inside `setupUnitTest()` and `setupRepositoryUnitTest()`. Add `_secureStore.clear();` to `_clearStorage()` so test isolation is preserved.

- [ ] **Step 2: Update `setupAuthentication()` to seed both the cache and the secure store**

```dart
Future<void> setupAuthentication() async {
  _secureStore['jwtToken'] = 'MOCK_TOKEN';
  AppLocalStorageCached.jwtToken = 'MOCK_TOKEN';
}
```

(Setting the cache directly avoids dragging in a real `loadCache()` call that could touch SharedPreferences before tests set them up.)

- [ ] **Step 3: Run analyzer to see the remaining broken sites**

```bash
fvm dart analyze --no-fatal-warnings test/ 2>&1 | grep -E "jwtToken|refreshToken"
```

- [ ] **Step 4: For each line, apply one of these substitutions**

**Pattern A — test seeds a token to simulate a logged-in user:**

```dart
// BEFORE
await AppLocalStorage().save(StorageKeys.jwtToken.key, "MOCK_TOKEN");

// AFTER (sync cache seeding — works for SecurityUtils and AuthInterceptor)
AppLocalStorageCached.jwtToken = "MOCK_TOKEN";
```

**Pattern B — test verifies that a token was persisted (e.g. `login_repository_test.dart`):**

If `LoginRepository.login` previously wrote `StorageKeys.jwtToken` directly, check `lib/features/auth/data/repositories/auth_repository_impl.dart` — that responsibility now belongs to `AuthSessionRepository`. The test should either:
  - Be moved to `auth_session_repository_impl_test.dart` (already covered there in Task 5), and the assertion in `login_repository_test.dart` deleted, **or**
  - Be re-pointed at the secure storage if `LoginRepository` still writes directly. Open the file and check; do not assume.

**Pattern C — `security_utils_test.dart` seeds a JWT for token-expiry checks:**

```dart
// BEFORE
await AppLocalStorage().save(StorageKeys.jwtToken.key, "header.payload.signature");

// AFTER
AppLocalStorageCached.jwtToken = "header.payload.signature";
```

`SecurityUtils.isTokenExpired()` reads from `AppLocalStorageCached.jwtToken`, so this still exercises the same code path.

**Pattern D — `test_utils.dart` global setup line (line 49):**

```dart
// BEFORE
await AppLocalStorage().save(StorageKeys.jwtToken.key, "MOCK_TOKEN");

// AFTER
AppLocalStorageCached.jwtToken = "MOCK_TOKEN";
```

- [ ] **Step 5: Run full test suite**

```bash
fvm flutter test
```

Expected: PASS. If any test that used to seed the JWT now reads `null` because the cached field isn't initialized at the test boundary, ensure `AppLocalStorageCached.jwtToken = null;` runs in `_clearStorage()` of `test_utils.dart` for isolation.

- [ ] **Step 6: Run analyzer**

```bash
fvm dart analyze
```

Expected: 0 errors.

- [ ] **Step 7: Commit**

```bash
git add test/
git commit -m "test(#129): mock secure storage channel + repair removed enum refs"
```

---

## Task 13: README + final verification

**Files:**
- Modify: `README.md` (auth section)

- [ ] **Step 1: Add a paragraph to the auth / security section of `README.md`**

Find the section that describes authentication (likely under "Architecture" or "Features"). Add (or weave in):

> **Token storage.** JWT and refresh tokens are persisted via `flutter_secure_storage` — iOS Keychain on Apple platforms and Keystore-backed `EncryptedSharedPreferences` on Android. Non-secret session fields (username, roles) remain in SharedPreferences for synchronous access. The first launch after upgrading from an older build runs a one-shot migration from the legacy plaintext keys into secure storage.

- [ ] **Step 2: Run the full test suite**

```bash
fvm flutter test
```

Expected: PASS (no regressions, all new tests green).

- [ ] **Step 3: Format check (CI gate)**

```bash
fvm dart format --set-exit-if-changed --line-length=120 .
```

Expected: exit 0. If anything is reformatted, run `fvm dart format . --line-length=120` and commit.

- [ ] **Step 4: Static analysis**

```bash
fvm dart analyze
```

Expected: 0 errors, 0 warnings.

- [ ] **Step 5: Commit + push + open PR**

```bash
git add README.md
git commit -m "docs(#129): note SecureStorage as token store in README"
git push -u origin feat/129-secure-storage-wiring
gh pr create --title "feat(#129): wire SecureStorage into DI and mask JWTs in logs" \
  --body "$(cat <<'EOF'
## Summary
- Routes JWT and refresh token through `flutter_secure_storage` instead of SharedPreferences.
- Splits `StorageKeys` into `SecureStorageKeys` (jwtToken, refreshToken) and `StorageKeys` (username, roles, language, theme, brightness).
- Adds `SessionMigration` for one-shot bootstrap migration from legacy plaintext keys.
- Adds `LogSanitizer.maskToken` and overrides `AuthSession.toString()` so tokens are structurally unloggable.
- Wires `TokenRefreshInterceptor` and bootstrap through `ISecureStorage`; cache layer refreshed after persist/refresh paths.

## Test plan
- [ ] `fvm flutter test` — full suite green
- [ ] Manually verify migration: install previous build, log in, upgrade, confirm session persists without re-login
- [ ] Confirm `AuthSession.toString()` masks tokens (new unit test)
- [ ] Confirm no debug log carries a raw JWT (grep + manual scan)

Closes #129

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-review checklist (run before marking the plan done)

- [ ] Every spec section maps to at least one task.
- [ ] No `TODO` / `TBD` / "implement later" in any step.
- [ ] Type names and method signatures are consistent across tasks (e.g. `ISecureStorage`, `SecureStorageKeys`, `AuthSessionRepository({required ISecureStorage secureStorage, AppLocalStorage? storage})`).
- [ ] Each task ends with a commit step.
- [ ] Tests precede implementation in every task that adds production code (TDD).
- [ ] Analyzer is expected to be dirty after Task 3 and clean after Task 12.
