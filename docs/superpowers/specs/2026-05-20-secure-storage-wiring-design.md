# SecureStorage Wiring + JWT Log Masking — Design

**Issue:** [#129](https://github.com/cevheri/flutter_bloc_advance/issues/129)
**Date:** 2026-05-20
**Author:** cevheri
**Status:** Approved, ready for plan

## Problem

1. `ISecureStorage` exists (`lib/infrastructure/storage/secure_storage.dart`) but is **not wired into DI**. The auth session repository persists the JWT in plaintext SharedPreferences.
2. SharedPreferences is world-readable on rooted Android, recoverable from iOS file system backups, and visible to any code sharing the app's UID. JWTs and refresh tokens belong in Keychain / Keystore-backed storage.
3. `lib/features/auth/application/login_bloc.dart:140` logs `data.toString()` on token-bearing entity. Today `Equatable.stringify = false` makes this safe, but flipping that flag — a common convenience change — would silently leak JWTs into every active log sink.

## Goals

- Persist JWT and refresh token via `flutter_secure_storage`.
- Keep `username` and `roles` in `AppLocalStorage` (used for synchronous reads).
- Migrate existing installations from SharedPreferences to SecureStorage without forcing logout.
- Make JWT leakage through logs structurally impossible — not just absent.

## Non-Goals

- Certificate pinning (#133), screen capture protection (#134), idle timeout (#130).
- Token encryption beyond what platform Keystore/Keychain provides.
- Refresh-token rotation policy.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Migration timing | **Eager (bootstrap, one-shot)** | Simple model; no half-migrated state carried through app lifetime. |
| Key enum | **Split into `SecureStorageKeys`** | Type system catches "wrong backend" at compile time. |
| `login_bloc.dart:140` | **Sanitize with `LogSanitizer.maskToken`** | Keep diagnostic value; mitigate leak risk. (Issue recommended deletion — we chose mask to preserve observability for OTP flow debugging.) |

## Architecture

### Storage layer

```
SecureStorageKeys enum  →  jwtToken, refreshToken
StorageKeys     enum  →  username, roles, language, theme, brightness
                         (jwtToken / refreshToken removed)
```

Files touched:
- `lib/infrastructure/storage/secure_storage.dart` — add `SecureStorageKeys` enum.
- `lib/infrastructure/storage/local_storage.dart` — remove `jwtToken` and `refreshToken` from `StorageKeys`.
- `lib/app/di/app_dependencies.dart` — add `ISecureStorage createSecureStorage() => FlutterSecureStorageAdapter()`.
- `lib/app/di/app_scope.dart` — construct once, expose to consumers.

### AuthSessionRepository — cross-backend atomicity

Repository constructor accepts both backends:

```dart
AuthSessionRepository({
  required ISecureStorage secureStorage,
  AppLocalStorage? storage,
});
```

`persist()` tracks writes to both backends. On any failure, rollback walks **both** lists. The invariant: callers never observe a partial session (e.g. `idToken` written but `username` missing, or vice versa).

`clear()` clears both backends.

### Eager migration

New file: `lib/infrastructure/storage/session_migration.dart`

```dart
class SessionMigration {
  static Future<void> run({
    required ISecureStorage secureStorage,
    required AppLocalStorage localStorage,
  });
}
```

Algorithm (per legacy key — `jwtToken`, `refreshToken`):
1. If `secureStorage.read(key)` returns a non-null value, **return** (already migrated, idempotent).
2. Read legacy value from `localStorage`. If null or empty, **return**.
3. Write to secure storage.
4. Remove from local storage.

Best-effort semantics: any exception logs a warning and returns. Worst case the user re-authenticates on next launch.

Bootstrap call order (`lib/app/bootstrap/app_bootstrap.dart`):
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `AppLogger.configure(...)`
3. **`await SessionMigration.run(...)`** — new step
4. `await AppLocalStorageCached.loadCache(secureStorage: ...)` — now reads `jwtToken` from secure storage

### AppLocalStorageCached — source change only

The cache layer is preserved so synchronous callers (`SecurityUtils.isUserLoggedIn()`, `isTokenExpired()`) keep working. Only the **source** of `jwtToken` changes:

```dart
static Future<void> loadCache({ISecureStorage? secureStorage}) async {
  final secure = secureStorage ?? FlutterSecureStorageAdapter();
  jwtToken = await secure.read(SecureStorageKeys.jwtToken.key);
  roles    = await AppLocalStorage().read(StorageKeys.roles.key);
  // language, username, theme, brightness — unchanged
}
```

Note: no static `refreshToken` field is added. The refresh token is only consumed asynchronously inside `TokenRefreshInterceptor`, so a synchronous cache provides no value there.

JWT still lives in process memory as a static field. That is a different threat model (memory dump) and out of scope.

### TokenRefreshInterceptor — read/save refresh token via SecureStorage

`lib/infrastructure/http/interceptors/token_refresh_interceptor.dart` currently reads `StorageKeys.refreshToken` from `AppLocalStorage` and persists the rotated tokens back there. With the split, both reads and writes move to `ISecureStorage`.

Constructor change:
```dart
TokenRefreshInterceptor({
  required Dio dio,
  required ISecureStorage secureStorage,
  OnSessionExpired? onSessionExpired,
});
```

`lib/infrastructure/http/api_client.dart` (line ~114) threads `secureStorage` through. `ApiClient` itself takes `ISecureStorage` from `AppDependencies` / `AppScope`.

After persisting rotated tokens, the interceptor refreshes the in-memory cache:
```dart
await _secureStorage.write(SecureStorageKeys.jwtToken.key, newIdToken);
if (newRefreshToken?.isNotEmpty == true) {
  await _secureStorage.write(SecureStorageKeys.refreshToken.key, newRefreshToken!);
}
await AppLocalStorageCached.loadCache(secureStorage: _secureStorage);
```

Otherwise `SecurityUtils.isUserLoggedIn()` and `isTokenExpired()` would observe the stale pre-refresh JWT until next bootstrap.

### Log sanitization

New file: `lib/core/logging/log_sanitizer.dart`

```dart
class LogSanitizer {
  /// Returns "abcd…wxyz" for normal-length tokens,
  /// "<redacted>" for tokens shorter than 8 chars,
  /// "<empty>" for null/empty.
  static String maskToken(String? token);
}
```

**Structural protection — `AuthSession.toString()` override:**

```dart
@override
String toString() => 'AuthSession('
  'idToken: ${LogSanitizer.maskToken(idToken)}, '
  'refreshToken: ${LogSanitizer.maskToken(refreshToken)}, '
  'username: $username, roles: $roles)';
```

This kills the failure mode at the source. Any current or future caller that does `'$session'`, `session.toString()`, or `Equatable.stringify = true` produces masked output.

**`login_bloc.dart:140`:**

```dart
_log.debug("onVerifyOtpSubmitted token: {}", [LogSanitizer.maskToken(data?.idToken)]);
```

## Test plan

| Test file | Scenarios |
|---|---|
| `test/features/auth/data/repositories/auth_session_repository_impl_test.dart` | (1) Round-trip: `idToken`/`refreshToken` written to secure backend, `username`/`roles` to local. (2) Cross-backend rollback: secure write succeeds, local write fails → secure side also rolled back. (3) `clear()` clears both. (4) Null `refreshToken` → secure key removed best-effort. |
| `test/infrastructure/storage/session_migration_test.dart` | (1) Migrates `jwtToken` and `refreshToken` from local → secure, removes from local. (2) Idempotent: second invocation is a no-op when secure already has the value. (3) Empty/missing legacy values → no-op. (4) Failure path logs warning and continues. |
| `test/infrastructure/http/interceptors/token_refresh_interceptor_test.dart` | Existing tests updated to construct with `ISecureStorage`; add scenarios for (1) refresh token read from secure storage, (2) rotated tokens written back to secure storage, (3) `AppLocalStorageCached.jwtToken` reflects the rotated value after refresh. |
| `test/core/logging/log_sanitizer_test.dart` | Boundary tests: null, empty, length 1, length 7, length 8, normal-length, very long. |
| `test/features/auth/domain/entities/auth_session_test.dart` | `toString()` does not contain the JWT value; produces masked form. |

## Acceptance criteria

- [ ] `ISecureStorage` exposed via `AppDependencies`, consumed by `AuthSessionRepository` and `TokenRefreshInterceptor`.
- [ ] JWT and refresh token persisted via SecureStorage; username and roles in `AppLocalStorage`.
- [ ] `SecureStorageKeys` enum separate from `StorageKeys`.
- [ ] One-shot eager migration on first launch after upgrade (idempotent).
- [ ] Cross-backend atomic-write rollback preserved.
- [ ] `TokenRefreshInterceptor` reads refresh token from secure storage and persists rotated tokens there; cache layer is refreshed after rotation.
- [ ] `login_bloc.dart:140` sanitized with `LogSanitizer.maskToken`.
- [ ] `LogSanitizer.maskToken()` helper under `lib/core/logging/`.
- [ ] `AuthSession.toString()` renders masked tokens (resilient to `stringify = true`).
- [ ] Unit tests cover round-trip, cross-backend rollback, migration (incl. idempotency), interceptor + secure storage, sanitizer, masked `toString()`.
- [ ] README auth section mentions where tokens are stored.

## References

- `lib/infrastructure/storage/secure_storage.dart`
- `lib/infrastructure/storage/local_storage.dart`
- `lib/app/di/app_dependencies.dart`
- `lib/app/di/app_scope.dart`
- `lib/app/bootstrap/app_bootstrap.dart`
- `lib/features/auth/data/repositories/auth_session_repository_impl.dart`
- `lib/features/auth/application/login_bloc.dart:140`
- `lib/features/auth/domain/entities/auth_session.dart`
- `lib/core/security/security_utils.dart`
- `lib/infrastructure/http/interceptors/token_refresh_interceptor.dart`
- `lib/infrastructure/http/api_client.dart`
- CLAUDE.md — logging rule on `stringify = true` leakage
