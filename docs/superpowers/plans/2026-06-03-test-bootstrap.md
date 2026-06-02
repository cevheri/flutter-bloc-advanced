# Test Bootstrap & TestEnv Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce a global test bootstrap (`flutter_test_config.dart`) that runs one-time config and an automatic, opt-out per-test environment reset, replacing the instance-based `TestUtils` with a static `TestEnv`, and remove the resulting per-file boilerplate.

**Architecture:** `test/flutter_test_config.dart` wraps the whole suite via `testExecutable`; it runs one-time config (binding, logger default, Equatable, mocktail fallbacks) and registers a global `setUp`/`tearDown` that calls `TestEnv.reset()` unless a file sets `TestEnv.autoReset = false`. `TestEnv` (in `test/support/test_env.dart`) owns the in-memory secure-store mock, storage reset, language seed, router setup, auth seeding, and the test `ApiClient`. Migration removes redundant `setupUnitTest`/`tearDownUnitTest`/`registerAllFallbackValues`/default `AppLogger.configure` calls across ~53 files.

**Tech Stack:** Flutter 3.44.0, Dart ^3.12.0, flutter_test, bloc_test, mocktail, FVM. Run tests with `fvm flutter test`.

---

## Key facts (do not violate)

- `flutter test` runs each test **file in its own isolate** → a static field in `TestEnv` is isolated per file; setting it in one file cannot leak to another.
- Callback order: `testExecutable` body registers the global `setUp` first; a file's own `setUpAll` runs after that body but before the first test's `setUp`. So a file flipping `TestEnv.autoReset = false` in `setUpAll` is observed by the global `setUp` at runtime.
- `flutter_test_config.dart` must be at `test/flutter_test_config.dart` (Flutter auto-discovers it for everything under `test/`).
- KEEP intentional `AppLogger.configure(...)` calls in tests that ASSERT on logging behavior (`test/core/logging/logger_test.dart`, `test/core/analytics/log_analytics_service_test.dart`, `test/infrastructure/http/interceptors/logging_interceptor_test.dart`, `logging_interceptor_verbose_test.dart`). Only remove configure calls that merely duplicate the global default and are pure setup boilerplate.

---

## File structure

- Create `test/support/test_env.dart` — static test-support API (replaces `test_utils.dart`).
- Create `test/flutter_test_config.dart` — global bootstrap.
- Modify `test/test_utils.dart` — temporary thin shim delegating to `TestEnv`, deleted in the final task.
- Modify ~53 test files — remove redundant setup/teardown/fallback/logger boilerplate; swap import to `test_env.dart`.
- Modify `test/infrastructure/storage/secure_storage_test.dart` and `test/core/security/screen_capture_protection_test.dart` — opt out of auto-reset.
- Modify `CLAUDE.md` — document the bootstrap + opt-out convention.

---

## Task 1: Create `TestEnv`

**Files:**
- Create: `test/support/test_env.dart`

- [ ] **Step 1: Write `test/support/test_env.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/app/router/app_router_strategy.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Static test-support harness. Replaces the old instance-based `TestUtils`.
///
/// One-time global config and the per-test reset are wired in
/// `test/flutter_test_config.dart`. Individual test files normally need
/// nothing; files that manage the secure-storage MethodChannel themselves
/// opt out with `setUpAll(() => TestEnv.autoReset = false);`.
class TestEnv {
  TestEnv._();

  /// When false, the global setUp/tearDown in flutter_test_config skip
  /// [reset]. Set in a file's `setUpAll` for tests that install their own
  /// MethodChannel handler (per-file isolate, so it never leaks). Defaults
  /// to true at isolate start.
  static bool autoReset = true;

  /// In-memory backing for the mocked flutter_secure_storage channel.
  /// Production code instantiates [FlutterSecureStorageAdapter] in several
  /// places (AuthInterceptor, TokenRefreshInterceptor, SessionCubit,
  /// AuthSessionRepository, LoginRepository.logout, SessionMigration); each
  /// routes through this MethodChannel. Without the mock those paths throw
  /// MissingPluginException.
  static final Map<String, String> _secureStore = {};

  static const _secureChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  /// Mock-backed client for tests: test AppConfig → MockInterceptor serves
  /// assets/mock/*.json; shared secure adapter → same MethodChannel mock the
  /// repo layer reads. Pass [dio] to inject a stub.
  static ApiClient apiClient({Dio? dio}) =>
      ApiClient(appConfig: const AppConfig.test(), secureStorage: FlutterSecureStorageAdapter(), dio: dio);

  /// Resets the per-test environment: re-installs the secure-storage mock,
  /// clears all storage, seeds language "en", and selects the goRouter
  /// strategy. Idempotent and cheap (in-memory).
  static Future<void> reset() async {
    _installSecureStorageMock();
    await _clearStorage();
    await AppLocalStorage().save(StorageKeys.language.key, 'en');
    AppRouter().setRouter(RouterType.goRouter);
  }

  /// Seeds a mock JWT in the secure-store backing. Call inside a test body or
  /// `setUp` (i.e. AFTER the global reset has cleared the store), never in
  /// `setUpAll`. Synchronous: the backing is just an in-memory map.
  static void authenticate() {
    _secureStore[SecureStorageKeys.jwtToken.key] = 'MOCK_TOKEN';
  }

  /// Always re-installs the handler. `secure_storage_test.dart` temporarily
  /// overrides the same channel and resets the handler to null in its
  /// tearDown; re-installing here is cheap and idempotent.
  static void _installSecureStorageMock() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_secureChannel, (
      call,
    ) async {
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

  static Future<void> _clearStorage() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    _secureStore.clear();
    await AppLocalStorage().clear();
  }
}
```

- [ ] **Step 2: Analyze the new file**

Run: `fvm dart analyze test/support/test_env.dart`
Expected: No issues found (the imports all exist; verified against current `test_utils.dart`).

- [ ] **Step 3: Commit**

```bash
git add test/support/test_env.dart
git commit -m "test: add static TestEnv harness (replaces TestUtils internals) (#150)"
```

---

## Task 2: Create the global bootstrap

**Files:**
- Create: `test/flutter_test_config.dart`

- [ ] **Step 1: Write `test/flutter_test_config.dart`**

```dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mock_classes.dart';
import 'support/test_env.dart';

/// Global test bootstrap, auto-discovered by `flutter test` for everything
/// under `test/`. Runs one-time config per isolate and an automatic per-test
/// environment reset. Files that manage the secure-storage MethodChannel
/// themselves opt out via `setUpAll(() => TestEnv.autoReset = false);`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // One-time per isolate.
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  EquatableConfig.stringify = true;
  registerAllFallbackValues();

  // Per-test, unless a file opts out.
  setUp(() async {
    if (TestEnv.autoReset) await TestEnv.reset();
  });
  tearDown(() async {
    if (TestEnv.autoReset) await TestEnv.reset();
  });

  await testMain();
}
```

- [ ] **Step 2: Analyze**

Run: `fvm dart analyze test/flutter_test_config.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add test/flutter_test_config.dart
git commit -m "test: add flutter_test_config global bootstrap with auto-reset (#150)"
```

---

## Task 3: Make `test_utils.dart` a thin shim

Keeps every existing `TestUtils()` call working while files are migrated incrementally. With the global bootstrap now active, the shim's methods just delegate to `TestEnv` (the global setUp already resets, so delegation is harmless/idempotent).

**Files:**
- Modify: `test/test_utils.dart` (replace entire contents)

- [ ] **Step 1: Replace `test/test_utils.dart` with the shim**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

import 'support/test_env.dart';

/// DEPRECATED compatibility shim. Use [TestEnv] directly. Removed once all
/// files are migrated (see plan #150). Delegates to TestEnv so existing
/// `TestUtils().setupUnitTest()` call sites keep working during migration.
class TestUtils {
  static ApiClient apiClient({Dio? dio}) => TestEnv.apiClient(dio: dio);

  Future<void> setupUnitTest() => TestEnv.reset();
  Future<void> setupRepositoryUnitTest() => TestEnv.reset();
  Future<void> tearDownUnitTest() => TestEnv.reset();
  void setupAuthentication() => TestEnv.authenticate();
}
```

- [ ] **Step 2: Run the full suite — bootstrap + shim must be green**

Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -3`
Expected: `All tests passed!` (count = current 1565). If failures appear, they will be in channel-override files — that is Task 4.

- [ ] **Step 3: Commit**

```bash
git add test/test_utils.dart
git commit -m "test: convert TestUtils to thin TestEnv shim during migration (#150)"
```

---

## Task 4: Opt out the conflicting self-mocking file

**Corrected after Task 3 full-suite run:** the only file that actually conflicts
with the global reset is `test/infrastructure/storage/local_storage_test.dart`
(4 failures). Its groups install their own `MockSharedPreferences` via
`localStorage.setPreferencesInstance(...)`, and the global `tearDown`'s
`SharedPreferences.setMockInitialValues({})` tramples them. The originally
predicted files (`secure_storage_test.dart`, `screen_capture_protection_test.dart`)
**pass without opt-out** (verified in Task 3) — do NOT opt them out (that would
strip a useful reset for no reason).

**Files:**
- Modify: `test/infrastructure/storage/local_storage_test.dart`

- [ ] **Step 1: Add opt-out**

Ensure this import is present (file is at `test/infrastructure/storage/`):

```dart
import '../../support/test_env.dart';
```

Add as the FIRST `setUpAll` in `main()` (create one if the file has none):

```dart
setUpAll(() => TestEnv.autoReset = false);
```

Because this file opts out of the global reset, it must keep managing its own
environment. Leave its existing `setUp`/`tearDown` (including any
`TestUtils().setupUnitTest()` / `tearDownUnitTest()` calls) intact for now —
they will be converted to explicit `TestEnv` calls in Task 6, NOT stripped.

- [ ] **Step 2: Run the file**

Run: `fvm flutter test test/infrastructure/storage/local_storage_test.dart -r compact 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 3: Commit**

```bash
git add test/infrastructure/storage/local_storage_test.dart
git commit -m "test: opt local_storage_test out of global auto-reset (self-mocks prefs) (#150)"
```

---

## Migration tasks (5–8): transform pattern

For every file in the listed group, apply this exact transform, then run the group, then commit.

**REMOVE these (now handled globally):**
- The `setUpAll`/`setUp` body call `await TestUtils().setupUnitTest();` or `await TestUtils().setupRepositoryUnitTest();` (and the `await testUtils.setupUnitTest();` field variants). If the enclosing `setUpAll`/`setUp` becomes empty, remove the whole `setUpAll(() {...})` / `setUp(() {...})` block.
- The `tearDown`/`tearDownUnitTest` body call `await TestUtils().tearDownUnitTest();` (remove the empty block if nothing else remains).
- Any standalone `registerAllFallbackValues();` call (now global).
- A `late TestUtils testUtils;` field + its `testUtils = TestUtils();` initialization, if present and now unused.

**REPLACE:**
- `TestUtils().setupAuthentication();` / `testUtils.setupAuthentication();` → `TestEnv.authenticate();`
  - Must sit in a test body or `setUp` (after the global reset), NOT in `setUpAll`. If a file currently calls it in `setUpAll`, move it to `setUp`.

**SWAP IMPORT:**
- `import '<relative>/test_utils.dart';` → `import '<relative>/support/test_env.dart';`
  - Compute the relative path from the test file to `test/support/test_env.dart`.
- Add `import '<relative>/support/test_env.dart';` if the file used `registerAllFallbackValues` (from `mocks/mock_classes.dart`) or `setupAuthentication` but had no `test_utils` import; otherwise the `mocks/mock_classes.dart` import may stay if other mocks are used.

**DO NOT** remove `AppLogger.configure(...)` in this pass (handled in Task 8).

After transforming a group:
- Run: `fvm flutter test <space-separated files in group> -r compact 2>&1 | tail -3` → expect `All tests passed!`
- If a file fails because auth was in `setUpAll`, move `TestEnv.authenticate()` into `setUp` or the test body.
- Commit the group.

---

## Task 5: Migrate group A — BLoC / Cubit / use-case tests

**Files (modify each, per the transform pattern above):**
- `test/app/session/session_cubit_test.dart`
- `test/app/shell/menu_bloc_test.dart`
- `test/app/shell/sidebar/sidebar_bloc_test.dart`
- `test/app/theme/theme_bloc_test.dart`
- `test/features/account/application/account_bloc_test.dart`
- `test/features/auth/application/change_password_bloc_test.dart`
- `test/features/auth/application/forgot_password_bloc_test.dart`
- `test/features/auth/application/login_bloc_test.dart`
- `test/features/auth/application/register_bloc_test.dart`
- `test/features/dashboard/application/dashboard_cubit_test.dart`
- `test/features/lifecycle/application/lifecycle_bloc_test.dart`
- `test/features/settings/application/settings_cubit_test.dart`
- `test/features/users/application/authority_bloc_test.dart`
- `test/features/users/application/user_editor_bloc_test.dart`
- `test/features/users/application/user_list_bloc_test.dart`
- `test/shared/dynamic_forms/application/dynamic_form_bloc_test.dart`
- `test/features/account/application/usecases/change_password_usecase_test.dart`
- `test/features/account/application/usecases/register_account_usecase_test.dart`
- `test/features/account/application/usecases/update_account_usecase_test.dart`
- `test/features/auth/application/usecases/authenticate_user_usecase_test.dart`
- `test/features/auth/application/usecases/send_otp_usecase_test.dart`
- `test/features/auth/application/usecases/verify_otp_usecase_test.dart`
- `test/features/users/application/usecases/save_user_usecase_test.dart`

- [ ] **Step 1:** Apply the transform pattern to every file above.
- [ ] **Step 2:** Run the group.

Run: `fvm flutter test test/app/session test/app/shell test/app/theme test/features/account/application test/features/auth/application test/features/dashboard/application test/features/lifecycle/application test/features/settings/application test/features/users/application test/shared/dynamic_forms/application -r compact 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "test: migrate bloc/cubit/usecase tests to TestEnv bootstrap (#150)"
```

---

## Task 6: Migrate group B — repository / infrastructure / router tests

**Files:**
- `test/app/connectivity/connectivity_banner_test.dart`
- `test/app/router/app_router_factory_test.dart`
- `test/app/router/app_router_strategy_test.dart`
- `test/app/router/router_test.dart`
- `test/core/feature_flags/feature_flag_service_test.dart`
- `test/core/security/idle_timeout_observer_test.dart`
- `test/core/security/security_utils_test.dart`
- `test/features/account/data/repositories/account_repository_test.dart`
- `test/features/auth/data/repositories/auth_session_repository_impl_test.dart`
- `test/features/auth/data/repositories/login_repository_test.dart`
- `test/features/users/data/repositories/authority_reporitory_test.dart`
- `test/features/users/data/repositories/user_repository_test.dart`
- `test/infrastructure/connectivity/connectivity_service_test.dart`
- `test/infrastructure/http/api_client_test.dart`
- `test/infrastructure/http/dev_console_capture_in_mock_mode_test.dart`
- `test/infrastructure/http/interceptors/connectivity_interceptor_test.dart`
- `test/infrastructure/http/interceptors/token_refresh_interceptor_test.dart`
- `test/infrastructure/storage/local_storage_test.dart`
- `test/infrastructure/storage/session_migration_test.dart`
- `test/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl_test.dart`

- [ ] **Step 1:** Apply the transform pattern. TWO exceptions for `local_storage_test.dart`: (a) it was opted out of auto-reset in Task 4, so DO NOT strip its `setupUnitTest`/`tearDownUnitTest` calls — instead convert `TestUtils().setupUnitTest()`/`tearDownUnitTest()` → `TestEnv.reset()` and keep them (the file manages its own reset); (b) it also calls `AppLogger.configure` — leave that line for Task 8.
- [ ] **Step 2:** Run the group.

Run: `fvm flutter test test/app/connectivity test/app/router test/core/feature_flags test/core/security/idle_timeout_observer_test.dart test/core/security/security_utils_test.dart test/features/account/data test/features/auth/data test/features/users/data test/infrastructure/connectivity test/infrastructure/http test/infrastructure/storage test/shared/dynamic_forms/data -r compact 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "test: migrate repository/infrastructure/router tests to TestEnv bootstrap (#150)"
```

---

## Task 7: Migrate group C — presentation / widget tests

**Files:**
- `test/app/shell/top_bar/breadcrumb_widget_test.dart`
- `test/core/security/screen_capture_protection_test.dart` (already opted out in Task 4 — only swap import / remove redundant `setupUnitTest` if present, keep the `autoReset = false`)
- `test/features/account/presentation/pages/account_screen_test.dart`
- `test/features/auth/presentation/pages/change_password_screen_test.dart`
- `test/features/auth/presentation/pages/forgot_password_screen_test.dart`
- `test/features/auth/presentation/pages/register_screen_go_router_test.dart`
- `test/features/auth/presentation/widgets/community_section_widget_test.dart`
- `test/features/auth/presentation/widgets/login_otp_email_widget_test.dart`
- `test/features/auth/presentation/widgets/login_otp_verify_widget_test.dart`
- `test/features/dashboard/presentation/pages/dashboard_page_test.dart`
- `test/features/dashboard/presentation/pages/home_screen_test.dart`
- `test/features/settings/presentation/pages/settings_screen_test.dart`
- `test/features/users/presentation/pages/list_user_screen_test.dart`
- `test/features/users/presentation/pages/user_editor_screen_test.dart`
- `test/features/users/presentation/pages/user_extended_info_page_test.dart`
- `test/shared/dynamic_forms/presentation/pages/dynamic_form_page_test.dart`
- `test/main/app_test.dart`

- [ ] **Step 1:** Apply the transform pattern. `login_otp_email_widget_test.dart` also calls `AppLogger.configure` — leave for Task 8. These files use `setupAuthentication` heavily; ensure each `TestEnv.authenticate()` is in a `setUp` or the test body, not `setUpAll`.
- [ ] **Step 2:** Run the group.

Run: `fvm flutter test test/app/shell/top_bar test/core/security/screen_capture_protection_test.dart test/features/account/presentation test/features/auth/presentation test/features/dashboard/presentation test/features/settings/presentation test/features/users/presentation test/shared/dynamic_forms/presentation test/main -r compact 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "test: migrate presentation/widget tests to TestEnv bootstrap (#150)"
```

---

## Task 8: Trim redundant `AppLogger.configure` calls

**Files (review each; remove ONLY if the call is `AppLogger.configure(isProduction: false, logFormat: LogFormat.simple)` AND lives in setUp/setUpAll boilerplate that no longer does anything else):**
- `test/app/di/repository_contracts_test.dart`
- `test/features/auth/data/mappers/auth_mapper_test.dart`
- `test/infrastructure/cache/shared_prefs_cache_storage_test.dart`
- `test/infrastructure/http/interceptors/auth_interceptor_test.dart`
- `test/infrastructure/http/interceptors/cache_interceptor_test.dart`
- `test/infrastructure/http/interceptors/resilience_interceptor_test.dart`
- `test/infrastructure/storage/local_storage_test.dart`
- `test/features/auth/presentation/widgets/login_otp_email_widget_test.dart`

**KEEP (logging-behavior tests — the configure call is part of the test intent):**
- `test/core/logging/logger_test.dart`
- `test/core/analytics/log_analytics_service_test.dart`
- `test/infrastructure/http/interceptors/logging_interceptor_test.dart`
- `test/infrastructure/http/interceptors/logging_interceptor_verbose_test.dart`
- `test/infrastructure/storage/secure_storage_test.dart` (opted out; configure may be intentional — keep unless clearly redundant default in an otherwise-empty block)

- [ ] **Step 1:** For each file in the REMOVE list, delete the redundant `AppLogger.configure(...)` line; if its block becomes empty, remove the block and any now-unused `app_logger` import.
- [ ] **Step 2:** Run the affected files.

Run: `fvm flutter test test/app/di/repository_contracts_test.dart test/features/auth/data/mappers/auth_mapper_test.dart test/infrastructure/cache/shared_prefs_cache_storage_test.dart test/infrastructure/http/interceptors test/infrastructure/storage/local_storage_test.dart test/features/auth/presentation/widgets/login_otp_email_widget_test.dart -r compact 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "test: drop redundant AppLogger.configure boilerplate (global default) (#150)"
```

---

## Task 9: Delete the shim

**Files:**
- Delete: `test/test_utils.dart`

- [ ] **Step 1: Verify no remaining references**

Run: `grep -rln "test_utils.dart\|TestUtils" test/ --include='*.dart'`
Expected: no output. If any file still references `TestUtils` or imports `test_utils.dart`, migrate it using the Task 5–7 transform pattern, then re-run this grep.

- [ ] **Step 2: Delete the shim**

```bash
git rm test/test_utils.dart
```

- [ ] **Step 3: Full suite + analyze + format**

Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -3`
Expected: `All tests passed!` (count = 1565, unchanged).

Run: `fvm dart analyze`
Expected: `No issues found!`

Run: `fvm dart format . --line-length=120 --set-exit-if-changed`
Expected: exit 0 (0 changed). If it reformats, `git add -A`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "test: remove TestUtils shim; TestEnv is the single support entry point (#150)"
```

---

## Task 10: Document the convention + finalize

**Files:**
- Modify: `CLAUDE.md` (Testing-related guidance)

- [ ] **Step 1: Add a Testing bootstrap note to `CLAUDE.md`**

Add under the existing testing guidance:

```markdown
### Test bootstrap

- `test/flutter_test_config.dart` runs once per isolate: binding init, logger
  default, `EquatableConfig.stringify`, mocktail fallback registration, and a
  global per-test environment reset (`TestEnv.reset()`).
- Tests need no manual setup for storage/router/secure-storage. Use
  `TestEnv.authenticate()` (in `setUp` or the test body) for auth-dependent
  tests, and `TestEnv.apiClient()` for the mock-backed client.
- Tests that install their own MethodChannel handler opt out with
  `setUpAll(() => TestEnv.autoReset = false);` (isolated per file).
```

- [ ] **Step 2: Full verification**

Run: `fvm flutter test --concurrency=4 -r compact 2>&1 | tail -3` → `All tests passed!`
Run: `fvm dart analyze` → `No issues found!`
Run: `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md && git commit -m "docs: document test bootstrap + TestEnv opt-out convention (#150)"
```

---

## Self-review notes

- **Spec coverage:** two new files (Tasks 1–2), opt-out (Task 4 + 10 doc), migration of all ~53 files (Tasks 5–7), redundant logger trim (Task 8), `test_utils.dart` deletion (Task 9), CLAUDE.md (Task 10). All spec sections covered.
- **Risk handling:** channel-override opt-out (Task 4) precedes bulk migration; auth-in-`setUpAll` pitfall called out in the transform pattern and Tasks 5/7; logger-behavior tests explicitly preserved (Task 8).
- **Type consistency:** `TestEnv.reset()`, `TestEnv.authenticate()`, `TestEnv.apiClient()`, `TestEnv.autoReset` used identically across all tasks.
- **No placeholders:** both new files have full source; the migration transform is a single concrete pattern applied to enumerated file lists.
```
