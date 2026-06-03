# Golden Tests — Phase 4 (Screens) Implementation Plan (#135)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Golden tests (light + dark) for the key screens, rendered with mocked BLoCs in a deterministic loaded state — the final golden phase. This phase **closes #135**.

**Architecture:** A shared `goldenScreen(...)` helper (localization + theme + phone surface) wraps each screen, which is supplied already inside its `BlocProvider`s with mock BLoCs seeded to a loaded state. Each screen golden reuses the mock-bloc setup from that screen's existing widget test (`test/features/.../presentation/pages/<screen>_test.dart`). Pattern from Phases 1–3 applies (`setUpAll(autoReset=false)`, light+dark, `pumpBeforeTest: pumpOnce`, CI/Ahem goldens only).

**Tech Stack:** Flutter 3.44.0, `alchemist` 0.14.0, `bloc_test`/`mocktail`, FVM.

---

## Established pattern + screen→BLoC map

- File: `setUpAll(() => TestEnv.autoReset = false);` (import `../../support/test_env.dart`); no `@Tags`; light + dark `goldenTest`; CI goldens under `test/goldens/screens/goldens/ci/`.
- Screens are full-size + animated/async → always `pumpBeforeTest: pumpOnce` and a fixed surface `SizedBox(width: 390, height: 844)`.
- Seed each mock BLoC: `when(() => bloc.state).thenReturn(<LoadedState>)` and `when(() => bloc.stream).thenAnswer((_) => Stream.value(<LoadedState>))` (or `const Stream.empty()`), with `whenListen` from `bloc_test` if needed. **Read the screen's existing widget test for the exact mock setup + state types**, then render the loaded state.

| Screen (widget class) | Existing test (harness source) | Mock BLoC(s) |
| --- | --- | --- |
| `LoginScreen` (`login_page.dart`) | `forgot_password_screen_test.dart` shows the provider set | `MockLoginBloc`, `MockAccountBloc` |
| `RegisterScreen` (`register_page.dart`) | `register_screen_go_router_test.dart` | `MockRegisterBloc`, `MockAccountBloc` |
| `ForgotPasswordScreen` (`forgot_password_page.dart`) | `forgot_password_screen_test.dart` | `MockForgotPasswordBloc`, `MockAccountBloc` |
| `ChangePasswordScreen` (`change_password_page.dart`) | `change_password_screen_test.dart` | `MockChangePasswordBloc`, `MockAuthorityBloc` |
| `AccountScreen` (`account_page.dart`) | `account_screen_test.dart` | `MockAccountBloc` |
| `UserListScreen` (`user_list_page.dart`) | `list_user_screen_test.dart` | `MockUserListBloc`, `MockAuthorityBloc` |
| `UserEditorScreen` (`user_editor_page.dart`) | `user_editor_screen_test.dart` | `MockUserEditorBloc`, `MockAuthorityBloc` |
| `DashboardScreen` (`dashboard_page.dart`) | `dashboard_page_test.dart` | `MockSystemDashboardCubit` |

**Deferred (documented, not forced):**
- `home_screen` / the responsive shell — rendered via `App().buildHomeApp()` with **real** DI blocs (not mockable to a single deterministic frame cleanly); its sub-parts (sidebar/top-bar/components) are already covered by component/widget goldens. Defer with a note.
- `settings_screen`, `user_extended_info_page`, `dynamic_form_page` — only if their existing tests show a clean mock-bloc loaded state; otherwise defer with a one-line reason. (Check during Task 4.)

---

## Task 1: Shared screen-golden helper

**Files:**
- Create: `test/goldens/support/golden_app.dart`

- [ ] **Step 1: Write the helper**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Wraps a screen for golden capture: full localization, the app theme, and a
/// phone-sized surface. Pass the screen already wrapped in its BlocProviders
/// (with mock BLoCs seeded to a loaded state). Use `dark: true` for the dark
/// variant.
Widget goldenScreen(Widget screen, {bool dark = false}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      home: screen,
    );

/// Standard phone surface for screen goldens.
const Size kGoldenScreenSize = Size(390, 844);
```

- [ ] **Step 2: Analyze**

Run: `fvm dart analyze test/goldens/support/golden_app.dart` → `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add test/goldens/support/golden_app.dart
git commit -m "test: add goldenScreen helper for screen golden tests (#135 phase 4)"
```

---

## Task 2: Auth screens

**Files (create each + generated `test/goldens/screens/goldens/ci/*.png`):**
- `test/goldens/screens/login_screen_golden_test.dart`
- `test/goldens/screens/register_screen_golden_test.dart`
- `test/goldens/screens/forgot_password_screen_golden_test.dart`
- `test/goldens/screens/change_password_screen_golden_test.dart`

- [ ] **Step 1:** For each screen, OPEN its existing widget test (table above) and copy its mock-BLoC setup (mock classes + how `state`/`stream` are stubbed). Seed the bloc(s) to the screen's **loaded/initial render** state. Write the golden file:

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
// + screen + bloc imports + mock_classes
import '../../mocks/mock_classes.dart';
import '../../support/test_env.dart';
import '../support/golden_app.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  // Build the screen wrapped in its providers with mocks seeded to a loaded state.
  Widget app({required bool dark}) {
    final loginBloc = MockLoginBloc();
    final accountBloc = MockAccountBloc();
    when(() => loginBloc.state).thenReturn(/* the screen's initial/loaded state */);
    whenListen(loginBloc, const Stream.empty(), initialState: /* same state */);
    // ...same for accountBloc...
    return goldenScreen(
      MultiBlocProvider(
        providers: [
          BlocProvider<LoginBloc>.value(value: loginBloc),
          BlocProvider<AccountBloc>.value(value: accountBloc),
        ],
        child: const LoginScreen(),
      ),
      dark: dark,
    );
  }

  goldenTest('LoginScreen — light', fileName: 'login_screen_light', pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestScenario(name: 'login', child: SizedBox.fromSize(size: kGoldenScreenSize, child: app(dark: false))));
  goldenTest('LoginScreen — dark', fileName: 'login_screen_dark', pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestScenario(name: 'login', child: SizedBox.fromSize(size: kGoldenScreenSize, child: app(dark: true))));
}
```

Use `whenListen` (from `bloc_test`) to give a deterministic state stream. Use
`BlocProvider.value` with the seeded mock. For the initial-form render, the
state is usually the bloc's `Initial`/`Loaded` variant — match what the existing
widget test seeds for a successful render.

- [ ] **Step 2: Generate**

Run: `fvm flutter test test/goldens/screens/login_screen_golden_test.dart test/goldens/screens/register_screen_golden_test.dart test/goldens/screens/forgot_password_screen_golden_test.dart test/goldens/screens/change_password_screen_golden_test.dart --update-goldens 2>&1 | tail -5` → `All tests passed!` + PNGs.
If a screen needs a `GoRouter` ancestor (uses `context.go`/`GoRouter.of`), wrap the screen in a minimal `MaterialApp.router`/`GoRouter` instead of `home:` — adapt the helper usage for that screen and report it.

- [ ] **Step 3: Verify (no --update) + analyze/format** → green/clean.
- [ ] **Step 4: Commit**

```bash
git add test/goldens/ && git commit -m "test: golden tests for auth screens (login/register/forgot/change password) (#135 phase 4)"
```

---

## Task 3: User & dashboard & account screens

**Files:**
- `test/goldens/screens/user_list_screen_golden_test.dart` — `UserListScreen`, mocks `MockUserListBloc` (seed a `UserListLoaded` with 2-3 sample users) + `MockAuthorityBloc`.
- `test/goldens/screens/user_editor_screen_golden_test.dart` — `UserEditorScreen`, mocks `MockUserEditorBloc` (seed a loaded/editing state with a sample user) + `MockAuthorityBloc`.
- `test/goldens/screens/dashboard_screen_golden_test.dart` — `DashboardScreen`, mocks `MockSystemDashboardCubit` (seed a loaded state).
- `test/goldens/screens/account_screen_golden_test.dart` — `AccountScreen`, mocks `MockAccountBloc` (seed loaded with a sample user).

- [ ] **Step 1:** For each, reuse the existing widget test's mock setup + the sample data/state it uses for a successful render; build via `goldenScreen` + `MultiBlocProvider`/`BlocProvider.value`; light + dark; `pumpBeforeTest: pumpOnce`; `kGoldenScreenSize`.
- [ ] **Step 2: Generate** (these 4 files) → pass + PNGs.
- [ ] **Step 3: Verify + analyze/format** → green/clean.
- [ ] **Step 4: Commit**

```bash
git add test/goldens/ && git commit -m "test: golden tests for user list/editor, dashboard, account screens (#135 phase 4)"
```

---

## Task 4: Remaining screens (best-effort) + deferrals

**Files (attempt; defer with a documented reason if not cleanly renderable):**
- `test/goldens/screens/settings_screen_golden_test.dart` — `SettingsScreen`: check `settings_screen_test.dart`; if it renders via a `SettingsCubit`, mock it to a loaded state. If it depends on global state with no mock, DEFER.
- `test/goldens/screens/dynamic_form_screen_golden_test.dart` — the dynamic form page: check its existing test (`test/shared/dynamic_forms/presentation/pages/dynamic_form_page_test.dart`); mock `MockDynamicFormBloc` to a `DynamicFormLoaded` with a small schema. If the schema wiring is too entangled, DEFER.

- [ ] **Step 1:** Attempt each. If a screen can't render to a clean deterministic frame in isolation, do NOT force it — skip the file and record a one-line reason for Task 5's docs. **`home_screen`/shell is deferred by design** (real-DI `buildHomeApp`; its parts are already goldened).
- [ ] **Step 2: Generate** any that worked → pass + PNGs.
- [ ] **Step 3: Verify + analyze/format** → green/clean.
- [ ] **Step 4: Commit**

```bash
git add test/goldens/ && git commit -m "test: golden tests for settings/dynamic-form screens; document deferrals (#135 phase 4)" || echo "nothing to commit"
```

---

## Task 5: Docs, full verification, close #135

**Files:**
- Modify: `docs/testing-architecture.md`

- [ ] **Step 1: Update the Goldens bullet** to reflect full coverage + deferrals.

In `docs/testing-architecture.md`, update the `- **Goldens:**` bullet to note that components, shared widgets, and key screens are covered, and list the deferred screens (home/shell rendered via real DI; plus any deferred in Task 4) with the reason "rendered via real DI / no clean mock state; their sub-widgets are covered by component/widget goldens."

- [ ] **Step 2: Full verification**

Run: `fvm flutter test --tags golden -r compact 2>&1 | grep -oE "\+[0-9]+: All tests passed!|Some tests failed" | tail -1` → `All tests passed!`.
Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | grep -oE "\+[0-9]+: All tests passed!|Some tests failed" | tail -1` → `All tests passed!`.
Run: `fvm dart analyze` → clean. `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0.
Run: `find test/goldens -type d \( -name linux -o -name macos \)` → none (CI goldens only).

- [ ] **Step 3: Commit docs**

```bash
git add docs/testing-architecture.md && git commit -m "docs: golden coverage complete (components/widgets/screens); note deferrals (#135 phase 4)"
```

(The PR for this phase is the one that closes #135 — put "Closes #135" in the PR body only, intentionally.)

---

## Self-review notes

- **Spec coverage:** the screen list from the spec, via existing-test harness
  reuse; home/shell + any non-mockable screens explicitly deferred with reasons
  (honest scoping, not silent omission).
- **DRY:** a single `goldenScreen` helper; per-screen setup copied from the
  screen's existing widget test (the harness already exists and is proven).
- **Pattern reuse:** `pumpBeforeTest: pumpOnce`, fixed surface, light+dark,
  CI-only goldens, `autoReset=false`.
- **Risk:** screens are the highest-maintenance goldens; deferrals are allowed
  and documented rather than forced.
