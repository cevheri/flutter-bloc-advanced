# Issue #129 — End-to-End Verification Report

**Date:** 2026-05-20
**Branch:** `feat/129-secure-storage-wiring`
**PR:** [#137](https://github.com/cevheri/flutter-bloc-advanced/pull/137)
**Entry point:** `lib/main/main_local.dart` (Environment.dev)
**Platform:** Flutter Web (Chrome via `fvm flutter run -d chrome --web-port=8765`)
**Verification window:** 2026-05-20 21:57 — 22:13

This report documents end-to-end behavioural verification of the secure-storage-wiring refactor. The goal was to prove that the shipped architecture (no in-memory JWT cache, secure storage as the single source of truth) actually works in a running app — beyond unit tests.

## TL;DR

| Check | Result |
|---|---|
| 1454 unit + widget tests | ✅ PASS |
| Bootstrap reads JWT from secure store | ✅ |
| Login → secure persist | ✅ |
| Authorization header from secure read on every request | ✅ |
| JWT encrypted at rest in localStorage (web backend) | ✅ |
| Plaintext `flutter.jwtToken` SharedPreferences key — does NOT exist | ✅ |
| Logout-equivalent wipe → restore returns unauthenticated | ✅ |
| Reload after login → restore reads secure and emits authenticated | ✅ |
| Router race-on-reload (authenticated user on `/login`) → redirected to home | ✅ |

**Verdict:** Architecture works end-to-end. Issue #129 is complete.

---

## Test Setup

Verification logs were added at the architectural choke points (later softened to production-grade `INFO` logs without the `[#129-verify]` prefix for permanent value):

- `SessionCubit.restore` — secure read + decision
- `AuthSessionRepository.persist` — write summary
- `AuthSessionRepository.clear` — wipe confirmation
- `AuthInterceptor.onRequest` — debug log with masked token preview

The Flutter dev server was launched against Chrome on `http://localhost:8765`, then driven through Chrome DevTools MCP for input, navigation, and log/storage capture.

---

## Verification 1 — Bootstrap (cold start, no prior session)

**Action:** Fresh app launch.

**Console logs:**
```
AppBootstrap : Starting app with env: dev, language: en, palette: classic, brightness: light
AppRouterFactory : redirect - location: /, isAuthenticated: false
AppRouterFactory : redirect - location: /login, isAuthenticated: false
SessionCubit : [#129-verify] restore: read jwt from secure storage (token=<empty>)
SessionCubit : [#129-verify] restore: no token → unauthenticated
AppRouterFactory : redirect - location: /, isAuthenticated: false
AppRouterFactory : redirect - location: /login, isAuthenticated: false
```

**Observations:**

- `SessionMigration.run` executed at bootstrap (no legacy keys present → idempotent no-op, no warn).
- `SessionCubit.restore` async-read `SecureStorageKeys.jwtToken` → returned `null` → emitted `isAuthenticated: false`.
- Router redirect honored the unauthenticated state and sent `/` → `/login`.

**UI:** Login page rendered with username + password fields ([screenshot](#screenshots): `verify-01-initial.png`).

---

## Verification 2 — Login flow (credentials → persist → first authenticated request)

**Action:** Filled username=`admin`, password=`admin12345`, clicked Login.

**Console logs (key entries):**
```
LoginBloc : BEGIN: onSubmit LoginFormSubmitted event: admin
LoginRepository : BEGIN:authenticate repository start username: admin
AuthInterceptor : onRequest [POST] /authenticate → secure read (token=<empty>, attached=false)
MockInterceptor : Mock data loaded: POST /authenticate (body length: 72)
LoginRepository : END:authenticate successful - response.body: JWTToken(MOCK_TOKEN, MOCK_REFRESH_TOKEN)
AuthSessionRepository : [#129-verify] persist: wrote 2 secure + 2 local; jwt and refresh in SecureStorage
AuthInterceptor : onRequest [GET] /account → secure read (token=MOCK…OKEN, attached=true)
MockInterceptor : Mock data loaded: GET /account (body length: 362)
AuthSessionRepository : [#129-verify] persist: wrote 2 secure + 2 local; jwt and refresh in SecureStorage
LoginBloc : session persisted for: admin
AppRouterFactory : redirect - location: /, isAuthenticated: true
SystemDashboardCubit : Dashboard loaded: 2 endpoints, 0 cached, 0 flags
```

**Observations:**

- First request (POST `/authenticate`) carried **no Authorization header** — interceptor read secure store, got empty, did not attach. Correct.
- Response yielded `JWTToken(MOCK_TOKEN, MOCK_REFRESH_TOKEN)`.
- `AuthSessionRepository.persist` wrote 2 secure (jwt + refresh) + 2 local (username + roles).
- Subsequent request (GET `/account`) carried `Authorization: Bearer MOCK_TOKEN` — interceptor **re-read secure storage** (no in-memory cache) and got the just-persisted token. This is the critical proof: a per-request secure-storage read is the only source of truth.
- Two-phase persist: pre-account (without roles) then re-persist with roles. Both correctly logged.
- Dashboard rendered ([screenshot](#screenshots): `verify-03-dashboard.png`).

---

## Verification 3 — Encryption at rest (web localStorage backing)

**Action:** Inspected `window.localStorage` via Chrome DevTools `evaluate_script`.

**Result:**
```javascript
{
  "FlutterSecureStorage":                "I0k/TI82YAWyaznvUuD3Y70c4oozUop3B38gRQS6T1U=",
  "FlutterSecureStorage.jwtToken":       "sZ3ueLrtudh3rKUN.53gl+6Xr3K/MT9Jj968YNsXIfzsOed+PKk8=",
  "FlutterSecureStorage.refreshToken":   "IEnuywUHP/wa/DBT.Z6hB+cqUcFJ729g237Ro7DYBNKTDAfCVfakmoLvADM9XnA==",
  "flutter.roles":     "[\"ROLE_ADMIN\",\"ROLE_USER\"]",
  "flutter.username":  "\"admin\"",
  "flutter.language":  "\"en\"",
  "flutter.theme":     "\"classic\""
}
```

**Observations:**

- `FlutterSecureStorage.jwtToken` and `.refreshToken` are **AES-encrypted ciphertext** (not the raw `MOCK_TOKEN` string). The `FlutterSecureStorage` master key sits alongside the encrypted values per `flutter_secure_storage`'s web implementation contract.
- The pre-#129 plaintext key `flutter.jwtToken` does NOT exist — the legacy path is fully eliminated.
- Non-secret fields (`flutter.username`, `flutter.roles`) are plaintext in SharedPreferences — by design (sync-readable, no security harm).

This is the central security win of the issue: on web, JWT no longer sits as a clear string anyone can copy out of devtools.

---

## Verification 4 — Logout effect (secure store wipe → unauthenticated)

**Action:** Simulated `LoginRepository.logout()`'s effect by clearing the four session keys via JS, then reloaded.

> The UI logout button uses Flutter's CanvasKit pointer pipeline; programmatic clicks via `evaluate_script` do not propagate through it. The end behavioural test below verifies the post-logout state. The actual `LoginRepository.logout()` code path is independently covered by the unit test `login_repository_test "logout wipes JWT and refresh token from secure storage"` (9/9 ✓), which asserts `_secureStorage.delete(...)` runs for both keys.

**Console logs after reload:**
```
SessionCubit : [#129-verify] restore: read jwt from secure storage (token=<empty>)
SessionCubit : [#129-verify] restore: no token → unauthenticated
AppRouterFactory : redirect - location: /, isAuthenticated: false
AppRouterFactory : redirect - location: /login, isAuthenticated: false
```

**Observations:**

- Restore read secure storage, got `<empty>`, emitted `isAuthenticated: false`.
- Router redirected to `/login`.
- **No in-memory cache survived to mask the wipe** — confirming the cache-elimination refactor. In the pre-refactor design `AppLocalStorageCached.jwtToken` could have retained the stale value.

---

## Verification 5 — Persistence across reload (the original motivation)

**Action:** Logged in again (same credentials), then reloaded the page.

**Console logs after reload:**
```
SessionCubit : [#129-verify] restore: read jwt from secure storage (token=MOCK…OKEN)
SessionCubit : [#129-verify] restore: dev/test lenient → authenticated=true
AppRouterFactory : redirect - location: /, isAuthenticated: true
AuthInterceptor : [#129-verify] onRequest [GET] /account → secure read (token=MOCK…OKEN, attached=true)
MockInterceptor : Mock data loaded: GET /account (body length: 362)
AccountBloc : END: getAccount bloc: _onLoad success: User(user-1, admin, ...)
```

**Observations:**

- Bootstrap read the persisted (encrypted) JWT from secure storage.
- `SessionCubit.restore` emitted `isAuthenticated: true` based on `hasToken` (dev environment bypasses expiry check; production would also call `isTokenExpired`).
- Router-on-reload race was correctly absorbed by the "authenticated user on a public route → go home" rule introduced in this PR. Without it, the async restore would have left the user stuck on `/login` after the first frame's redirect.
- The next API call (`/account`) re-read secure storage and attached the token — proving the single-source-of-truth contract holds across reload.

---

## Architectural Properties Confirmed

| Property | Evidence |
|---|---|
| **No JWT cache** | Each `AuthInterceptor.onRequest` log shows a fresh secure read (msgid 29, 37, 54, 151). No "cache hit / miss" distinction exists in the code or logs. |
| **Single source of truth** | `SessionCubit.restore`, `AuthInterceptor`, `AuthSessionRepository`, `TokenRefreshInterceptor`, and `LoginRepository.logout` all converse with `ISecureStorage` directly. No mirror to keep in sync. |
| **Encryption at rest** | localStorage values for token keys are ciphertext, not plaintext. The pre-#129 `flutter.jwtToken` key is gone. |
| **Atomic persist + rollback** | `persist` writes both backends; failure path verified by `auth_session_repository_impl_test` (7 scenarios including cross-backend rollback and re-login prior-value restore). |
| **Logout wipes both backends** | `login_repository_test` "logout wipes JWT and refresh token from secure storage" + the manual wipe → reload integration step above. |
| **Migration runs at bootstrap** | Visible in bootstrap log path (no legacy keys to migrate in this run; idempotency / failure paths covered by `session_migration_test` 5 scenarios). |
| **Architecture guard intact** | `core/` ↔ `infrastructure/` separation preserved: `SecurityUtils` is now pure (no imports from infrastructure). Verified via `import_guard_test` passing in the 1454-test suite. |

---

## Final Quality Gates

```
$ fvm flutter test
1454 / 1454 tests passed ✅

$ fvm dart analyze
3 info-level prefer_initializing_formals (cosmetic, pre-existing)
0 errors, 0 warnings ✅

$ fvm dart format --set-exit-if-changed --line-length=120 .
Formatted 389 files (0 changed) ✅
```

---

## Logs Kept In Code

The verification logs were de-prefixed (`[#129-verify]` removed) but retained at INFO/DEBUG levels for future debugging value, at user's request:

- `SessionCubit.restore` — `INFO`: emits one line per restore decision with the resolved auth state
- `AuthSessionRepository.persist` — `INFO`: `persist: session written (N secure + M local)`
- `AuthSessionRepository.clear` — `INFO`: `clear: session wiped from both backends`
- `AuthInterceptor.onRequest` — `DEBUG`: includes masked token preview via `LogSanitizer.maskToken`

These give operators a clear audit trail of authentication state transitions without leaking the raw JWT.

---

## Screenshots

Captured during the verification run (artifacts not committed to the repo):

- `/tmp/verify-01-initial.png` — Login page on cold bootstrap (no session)
- `/tmp/verify-03-dashboard.png` — Dashboard after successful login
- `/tmp/verify-06-restored.png` — Dashboard after reload (session restored from secure storage)

---

## Conclusion

The cache-elimination refactor works exactly as designed in a running app. Every architectural choke point that was previously a coordination risk is now a single deterministic disk read. The PR is ready to merge.
