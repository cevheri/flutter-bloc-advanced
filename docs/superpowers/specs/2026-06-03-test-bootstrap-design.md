# Test Bootstrap & `TestEnv` Refactor — Design (#150)

**Date:** 2026-06-03
**Issue:** #150 (test-infrastructure audit follow-up)
**Status:** Approved (design)

## Problem

There is no global test bootstrap. All per-test setup is invoked manually,
producing duplication and inconsistency across the suite:

- 54 files call `TestUtils().setupUnitTest()` / `setupRepositoryUnitTest()`.
- 45 of those invoke it via `setUpAll` (once per file — does **not** reset
  state between tests in the file; relies on `tearDown` or test independence),
  9 via `setUp`.
- 11 files call `setupUnitTest` but never `tearDownUnitTest`.
- 12 files call `AppLogger.configure(...)` directly.
- `registerAllFallbackValues()` (mocktail fallbacks) is invoked ad hoc.
- The helper is instance-based (`TestUtils()`) despite holding only static
  state — a misleading API.

Without a global hook there is also no single place to host cross-cutting
concerns the project is about to need (golden font loading — #135).

## Goals

- One global bootstrap that runs once per test isolate for one-time config.
- Automatic per-test environment reset by default, with a clean opt-out.
- A coherent, well-named helper API replacing `TestUtils`.
- Reduce per-file boilerplate across the 54 files.
- No behavior change in assertions; full suite stays green.

## Non-Goals (YAGNI)

- Golden font loading — deferred to #135 (a documented seam may be left).
- `withClock` / time determinism — deferred to #148.

## Key Technical Facts

1. `flutter test` runs each test **file in its own isolate**, so a top-level
   mutable static in test support code is **isolated per file** — setting it in
   one file cannot leak into another.
2. `flutter_test_config.dart` exposes
   `Future<void> testExecutable(FutureOr<void> Function() testMain)`, which
   wraps the whole file. Calling `setUp` / `tearDown` inside it registers them
   globally for every test in that file.
3. Callback ordering: the `testExecutable` body (which registers the global
   `setUp`) runs first; a file's own `setUpAll` runs **after** that body but
   **before** the first test's `setUp`. Therefore a file can flip an opt-out
   flag in its `setUpAll` and the global `setUp` will observe it at runtime.

## Architecture — two new files

### `test/support/test_env.dart`

Replaces `test/test_utils.dart`. Static API (no instances):

- `static bool autoReset` — opt-out flag (default `true`).
- `static Future<void> reset()` — clears secure-store backing + SharedPreferences,
  seeds language `"en"`, sets the router to `goRouter`, and (idempotently)
  installs the `flutter_secure_storage` MethodChannel mock. Consolidates the
  former `setupUnitTest` and `setupRepositoryUnitTest` into one method.
- `static void authenticate()` — seeds a mock JWT in the secure-store backing.
- `static ApiClient apiClient({Dio? dio})` — unchanged test client helper.
- Retains the in-memory secure-store map + MethodChannel handler from
  `TestUtils`, with its existing explanatory comments.

### `test/flutter_test_config.dart`

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // One-time per isolate
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  EquatableConfig.stringify = true;
  registerAllFallbackValues();

  // Per-test, unless a file opts out
  setUp(() async { if (TestEnv.autoReset) await TestEnv.reset(); });
  tearDown(() async { if (TestEnv.autoReset) await TestEnv.reset(); });

  await testMain();
}
```

## Opt-out mechanism

Files that override the secure-storage channel themselves (e.g.
`secure_storage_test.dart`, whose C3 throw-on-failure tests reset the handler
to `null`) opt out in their own `setUpAll`:

```dart
setUpAll(() => TestEnv.autoReset = false);
```

Isolated per file (fact #1), so it affects nothing else. This is documented in
`test_env.dart` and in CLAUDE.md's testing section.

## Migration (~54 files)

Mechanical, applied in vetted groups with a full `flutter test` run after each:

1. Add `test/support/test_env.dart` + `test/flutter_test_config.dart`; keep
   `test_utils.dart` temporarily as a thin re-export to avoid a big-bang change.
2. Per group of files:
   - Remove `TestUtils().setupUnitTest()` / `setupRepositoryUnitTest()` /
     `tearDownUnitTest()` calls (global handles reset).
   - Remove direct `AppLogger.configure(...)` (12 files).
   - Remove manual `registerAllFallbackValues()` calls.
   - Replace `TestUtils().setupAuthentication()` →
     `TestEnv.authenticate()` (called in the test body or `setUp`, i.e. after
     the global reset has run).
3. Opt out the channel-override files (`secure_storage_test.dart`, and any
   others surfaced by failures) via `TestEnv.autoReset = false`.
4. Delete `test_utils.dart` once all references are migrated.

## Risks & mitigations

- **Global `setUp` runs for ~86 pure-unit files too.** Harmless (cheap,
  idempotent) but a small constant cost. Accepted; `reset()` is fast (in-memory).
- **Secure-storage tests.** Validate ordering / opt-out explicitly; these are
  the highest-risk files. The existing hazard is already documented in
  `TestUtils` and carried over.
- **Auth-dependent tests.** Because the global `setUp` clears the secure store
  before each test, `TestEnv.authenticate()` must run *after* it (test body or
  `setUp`), not in `setUpAll`. Migration checks each of the 45 call sites.

## Verification

- `dart format . --line-length=120 --set-exit-if-changed` clean.
- `dart analyze` clean.
- Full `flutter test` (1565+ tests) green after each migration group.
- Spot-check that opted-out files behave identically to before.

## Acceptance

- `test/flutter_test_config.dart` runs for the whole suite.
- Per-file global-config boilerplate removed; reset is automatic with opt-out.
- `test_utils.dart` removed; `TestEnv` is the single test-support entry point.
- No assertion behavior changed.
