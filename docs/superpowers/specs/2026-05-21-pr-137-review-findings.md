# PR #137 — Independent Review Findings & Resolution Tracker

> **Source:** 5-agent parallel review (silent-failure-hunter, code-reviewer, pr-test-analyzer, type-design-analyzer, comment-analyzer) on 2026-05-21.
>
> **Scope:** Findings resolved within this PR (single merge). Items marked **deferred** become follow-up issues.

## Verdict snapshot

| Severity | Count | In-PR | Deferred |
|---|---:|---:|---:|
| Critical | 5 | **5 ✓** | 0 |
| Important | 8 | **8 ✓** | 0 |
| Suggestion | 11 | TBD | TBD |

**Critical phase status:** complete. 1479/1479 tests passing, format clean, no new analyzer warnings.
**Important phase status:** complete. 1478/1478 tests passing, format clean, no new analyzer warnings.

---

## 🔴 Critical (in-PR fix required)

- [x] **C1** — Wrapped both writes in a try/catch. Prior id_token snapshotted before persist; prior refresh_token already in hand from line 184. On any write failure, `_restoreOrDelete` puts both keys back to prior values (or deletes if absent), and `_performRefresh` returns null → session-expired callback fires for a clean re-auth instead of a torn id/refresh pair. New test `rolls back rotated tokens to prior values when refresh_token write throws` covers it (28/28 in the file).
- [x] **C2** — Added `RefreshDioFactory` injection (default = library factory). New tests cover: (a) full happy path — persists rotated tokens, retries with new Bearer, marker stamped, `handler.resolve` called; (b) refresh response omits new refresh_token — keeps existing one; (c) `id_token` missing → logout + original 401 surfaces; (d) `id_token=""` → logout, no garbage persisted. No new dependency added.
- [x] **C3** — Added `test/infrastructure/storage/secure_storage_test.dart` with 5 tests driving the production `flutter_secure_storage` MethodChannel directly: PlatformException on each of read/write/delete/deleteAll propagates; absent-key read returns null (the only non-throw null path).
- [x] **C4** — Added `test/infrastructure/http/interceptors/auth_interceptor_test.dart` with 4 behavior tests: Bearer attached on token; no header on null or empty; read-throws does not crash (anonymous fallback). Drives interceptor directly with a capturing `RequestInterceptorHandler` — no Dio/HTTP plumbing.
- [x] **C5** — Audit clarified the picture: `flutter_secure_storage` ≥ 10 uses custom AES-GCM ciphers by default on Android (Jetpack Crypto is deprecated, library replaced it). The `encryptedSharedPreferences` flag is itself deprecated and ignored. The real lever is **iOS/macOS Keychain accessibility**: pinned `first_unlock_this_device` so secrets never sync to iCloud Keychain. README updated.

---

## 🟡 Important

- [x] **I1** — Sealed hierarchy: `SessionUnknown` / `SessionAuthenticated` / `SessionUnauthenticated({reason})` with a `SessionExpiredReason` enum (noToken/expired/storageError/unknown). Router redirect now pattern-checks `state is SessionAuthenticated`; the load-bearing "Token expiry is no longer checked here" prose comment is gone. Tests rewritten with an exhaustive-switch test that the compiler enforces against future variant additions; new prod-mode expired-token test (also closes I8a).
- [x] **I2** — `LoginRepository.logout` now delegates to `IAuthSessionRepository.clear`. Constructor accepts an optional session repository; falls back to building one from `secureStorage`. Eliminated 30+ lines of duplicated cleanup code; sole remaining responsibility of `logout` is log-band routing the Result. Repository contract test seeds logger so the new internal AuthSessionRepository construction doesn't trip.
- [x] **I3** — Three-layer defense: (a) `_createDio` now logs a loud `warn` when `secureStorage` is null at construction time so the divergence is auditable from logs; (b) `setupUnitTest` / `setupRepositoryUnitTest` wire `ApiClient.secureStorage = FlutterSecureStorageAdapter()` so the test harness can't accidentally fall back to a private adapter instance; (c) new guard test in `api_client_test.dart` asserts `ApiClient.secureStorage` is non-null after `setupUnitTest`, locking the invariant.
- [x] **I4** — Backend constants consolidated into private `_RefreshEndpoint` (path + request/response keys) and `_AuthHeader` (name + bearer prefix) classes at the top of `token_refresh_interceptor.dart`. NOT routed through `JWTToken.fromJson` because that would create an `infrastructure → features` import that violates the project dependency rules (`grep -rn "import 'package:flutter_bloc_advance/features" lib/infrastructure` confirmed it would be the only such import in the codebase).
- [x] **I5** — `_retriedAfterRefresh` is now a private `Expando<bool>` keyed on `RequestOptions`. Magic-string flag in `extra` is gone; `'true'`/`1` mistype is structurally impossible. Two `@visibleForTesting` helpers (`debugMarkAsRetried`, `debugIsMarkedAsRetried`) keep the marker exercisable from tests without leaking the Expando.
- [x] **I6** — `save()` and `remove()` now treat `loadCache()` failure as a cache-staleness warn, not a save failure. The successful underlying write is no longer rolled back by a transient SharedPreferences read error.
- [x] **I7** — Default `_ => null` removed; switch enumerates every `StorageKeys` variant. Future enum additions surface as missing-case build errors instead of silent rollback-to-null (== delete).
- [x] **I8** — `clear()` throw-on-refuse contract pinned with two tests: `MockSharedPreferences.clear() == false` → `throwsA(isA<StateError>())`; `clear()` exception propagates. Prod-mode expired-token branch covered as part of I1 (see new SessionCubit test).

---

## 🟢 Suggestions

- [ ] **S1** — Introduce `Secret` wrapper type for `idToken`/`refreshToken` (turns masked `toString` from convention into structural guarantee).
- [ ] **S2** — `LogSanitizer` and `SessionMigration` are state-less static-method classes. Convert to top-level functions.
- [ ] **S3** — `JWTToken.fromJson` declared return type is `JWTToken?` but body never returns null. Tighten to non-nullable.
- [ ] **S4** — Equatable.stringify misunderstanding in comments. `jwt_token.dart:51-54` and `auth_session.dart:25-26` describe a "stringify could bypass the mask" scenario that doesn't exist — explicit `toString()` override wins regardless. Simplify.
- [ ] **S5** — `app_bootstrap.dart:36-38` "ahead of any await on a network-dependent path" comment is rescued by qualifier. Line 25 already has an await above. Replace with positive ordering invariant.
- [ ] **S6** — `token_refresh_interceptor.dart:23-26` interceptor-order ASCII diagram is already stale (`ConnectivityInterceptor` missing). Delete diagram; point to `ApiClient._createDio` as source of truth.
- [ ] **S7** — `app_router.dart:74-77` "Token expiry is no longer checked here" reads as cargo cult once the deleted code is forgotten. Rewrite forward-looking.
- [ ] **S8** — `local_storage.dart:6-15` "six coordinated write paths" historical paragraph will be meaningless in 6 months. Keep present-tense invariant only.
- [ ] **S9** — `lib/core/testing/app_key_constants.dart` is imported by 6 production widgets. The `core/testing/` path is misleading. Rename to `lib/core/keys/widget_keys.dart` or `lib/shared/widgets/widget_keys.dart`. (Pre-existing — deferred.)
- [ ] **S10** — `SecureStorageKeys.jwtToken('jwtToken')` reuses the legacy SharedPreferences key string. Once migration window closes, rename to `'secure.jwt'`. Mark with TODO.
- [ ] **S11** — `SessionCubit.markAuthenticated`, `markLoggedOut`, `refresh` are undocumented public mutators on a security-critical cubit. Add dartdoc.

---

## ✅ Strengths (recognized across multiple agents)

- `SessionMigration` write-verify-then-remove pattern is exemplary; idempotent cleanup of lingering plaintext.
- `AuthSessionRepository.persist` snapshot-and-rollback correctly restores prior values, not just deletes — empty refresh-token edge handled.
- `_inFlightRefresh` whenComplete timing is correct under Dio's QueuedInterceptor + single-thread event loop.
- Loop-prevention marker (`_retriedAfterRefresh`) test pins semantics with baseline-delta counter.
- Stale-header tests cover both throw-from-read fallback and rotated-token short-circuit.
- Logging discipline: 100% parameterized `{}` substitution in all changed files.
- Architecture boundaries respected (no new cross-feature imports, `core/` still depends on nothing in `infrastructure/`/`features/`).
- `ISecureStorage` failure contract documentation is precise about "read does NOT collapse platform failures to null".
- README + design docs + E2E verification report (Chrome DevTools-validated on real web build).
