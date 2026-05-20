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
4. `await AppLocalStorageCached.loadCache()` — loads non-JWT fields (roles, language, theme, brightness, username) from SharedPreferences

> **Note (shipped behavior diverges from initial design):** the original design proposed caching `jwtToken` in `AppLocalStorageCached` after reading it from secure storage. During PR review the sync-cache approach proved to require six coordinated write paths (persist, refresh, logout, rollback, clear, bootstrap) — each a potential source of stale-token bugs. The shipped design eliminates that cache entirely. See the "Shipped architecture" section below.

### AppLocalStorageCached — non-JWT fields only

The cache layer holds only fields that legitimately live in SharedPreferences (`roles`, `language`, `username`, `theme`, `brightness`) and benefit from synchronous reads. `loadCache()` takes no `ISecureStorage` parameter; the JWT is not cached.

```dart
static Future<void> loadCache() async {
  roles    = await AppLocalStorage().read(StorageKeys.roles.key);
  language = await AppLocalStorage().read(StorageKeys.language.key) ?? "en";
  // username, theme, brightness — same pattern
}
```

### TokenRefreshInterceptor — read/save refresh token via SecureStorage

`lib/infrastructure/http/interceptors/token_refresh_interceptor.dart` reads `SecureStorageKeys.refreshToken` from `ISecureStorage` and persists rotated tokens there. Constructor:

```dart
TokenRefreshInterceptor({
  required Dio dio,
  ISecureStorage? secureStorage,  // defaults to FlutterSecureStorageAdapter()
  OnSessionExpired? onSessionExpired,
});
```

No cache sync is needed after rotation: `AuthInterceptor` reads from secure storage on every request, so the next outgoing request picks up the rotated JWT directly.

### Shipped architecture — JWT lives only in `ISecureStorage`

After PR review the cache layer for JWT was removed entirely. The shipped data flow:

| Caller | How it reads JWT |
|---|---|
| `AuthInterceptor.onRequest` | `await _secureStorage.read(...)` on every request |
| `SessionCubit.restore` / `refresh` | `await _secureStorage.read(...)` → `SecurityUtils.hasToken(token)` + `isTokenExpired(token)` (pure) |
| `AuthSessionRepository.persist` / `clear` | writes / deletes via `ISecureStorage` |
| `TokenRefreshInterceptor` | reads / writes via `ISecureStorage` |
| `LoginRepository.logout` | deletes via `ISecureStorage`, then `AppLocalStorage.clear()` |

`SecurityUtils` is a pure-function module: callers hand it a token string, it returns a derived boolean. This keeps `core/` free of `infrastructure/` imports per the architecture guard.

`SessionCubit` owns the only "is the user authenticated?" decision for UI / router consumers. The router redirect reads `state.isAuthenticated` synchronously; it no longer calls `SecurityUtils.isTokenExpired()` directly.

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
| `test/infrastructure/http/interceptors/token_refresh_interceptor_test.dart` | Existing tests updated to construct with `ISecureStorage`; scenarios cover (1) refresh token read from secure storage and (2) rotated tokens written back to secure storage. No cache assertion needed — `AuthInterceptor` re-reads from secure storage on every request. |
| `test/core/logging/log_sanitizer_test.dart` | Boundary tests: null, empty, length 1, length 7, length 8, normal-length, very long. |
| `test/features/auth/domain/entities/auth_session_test.dart` | `toString()` does not contain the JWT value; produces masked form. |

## Acceptance criteria

- [ ] `ISecureStorage` exposed via `AppDependencies`, consumed by `AuthSessionRepository` and `TokenRefreshInterceptor`.
- [ ] JWT and refresh token persisted via SecureStorage; username and roles in `AppLocalStorage`.
- [ ] `SecureStorageKeys` enum separate from `StorageKeys`.
- [ ] One-shot eager migration on first launch after upgrade (idempotent).
- [ ] Cross-backend atomic-write rollback preserved.
- [ ] `TokenRefreshInterceptor` reads refresh token from secure storage and persists rotated tokens there. No in-memory cache to refresh — `AuthInterceptor` reads JWT directly from secure storage on every request, so the next outgoing request automatically picks up the rotated token.
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
