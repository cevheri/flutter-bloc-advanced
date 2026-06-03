# End-to-End Smoke Test — Design (#152)

**Date:** 2026-06-03
**Issue:** #152 (test-infrastructure audit follow-up)
**Status:** Superseded by re-scope during implementation — see note below.

> **⚠️ Re-scoped during the spike (what actually shipped):** the `integration_test`
> package turned out to require a device (local `flutter test integration_test/`
> errors "more than one device"; it only ran via `-d linux` with heavy native
> deps), so "headless CI" was not achievable cheaply. **The implemented solution
> is a full-app *widget* smoke at `test/integration/app_smoke_test.dart`**
> (`TestWidgetsFlutterBinding`) that boots the app in mock mode and drives
> login → dashboard, runs headless under the existing `flutter test` (no CI
> changes), and the unused `integration_test` dev dependency was **removed**. The
> sections below describe the original `integration_test/`-based design and are
> kept only as the record of intent — they do NOT match the shipped code. See
> `docs/testing-architecture.md` → "End-to-end smoke" for the actual approach.

## Problem

`integration_test` was a declared dev dependency but there was **no `integration_test/`
directory** — an unused dependency and a missing e2e layer. The suite has strong
unit/widget/golden coverage but nothing that boots the whole app and exercises
routing + DI + BLoCs + storage + the mock HTTP layer together. A template
benefits from one real happy-path smoke (cold start → login → dashboard).

## Decision

Add the e2e layer using the `integration_test` package (resolves the unused dep,
idiomatic, on-device-capable) with a single mock-mode happy-path smoke, and run
it headless in CI (no emulator).

## Key facts (feasibility)

- `App({language, dependencies = const AppDependencies(), secureStorage, analytics})`
  (`lib/app/app.dart`) **self-wraps** — it builds the full provider tree
  (`AppConfig`, repositories, BLoCs, `GoRouter`) from its `dependencies`. Pumping
  `App(language: 'en')` works (already proven by `test/main/app_test.dart`).
- Dev/test mode serves `assets/mock/*.json` via `MockInterceptor`;
  `POST_authenticate.json` returns `{ "id_token": "MOCK_TOKEN", ... }`, so a login
  with any credentials succeeds against mocks.
- Login keys: `loginTextFieldUsernameKey`, `loginTextFieldPasswordKey`,
  `loginButtonSubmitKey`.
- `integration_test/` does **not** get `test/flutter_test_config.dart` (that's
  auto-discovered only under `test/`), so the smoke must do its own setup
  (secure-storage MethodChannel mock + storage reset). It reuses `TestEnv.reset()`
  via a relative import to avoid duplicating that ~15-line mock.
- `flutter test integration_test/` runs the `IntegrationTestWidgetsFlutterBinding`
  **headless** under the normal test runner — no device/emulator needed for CI.

## Architecture

### `integration_test/app_smoke_test.dart`
```
IntegrationTestWidgetsFlutterBinding.ensureInitialized();
setUp(() => TestEnv.reset());            // secure-storage mock + storage, via ../test/support/test_env.dart

testWidgets('cold start → login → dashboard (mock mode)', (tester) async {
  await tester.pumpWidget(const App(language: 'en'));   // mock-mode deps if default isn't mock, pass dependencies
  await tester.pumpAndSettle();
  // login screen
  await tester.enterText(find.byKey(loginTextFieldUsernameKey), 'admin');
  await tester.enterText(find.byKey(loginTextFieldPasswordKey), 'admin');
  await tester.tap(find.byKey(loginButtonSubmitKey));
  await tester.pumpAndSettle();
  // dashboard/home reached
  expect(find.byType(ResponsiveScaffold), findsOneWidget); // or find.text('Dashboard')
});
```

Exercises router + DI + `LoginBloc` + repositories + `ApiClient`(MockInterceptor)
+ secure storage together — the real e2e value.

### Setup reuse
`import '../test/support/test_env.dart';` → `TestEnv.reset()` installs the
secure-storage mock and clears storage. (Importing `test/` from `integration_test/`
is a deliberate, documented reuse to avoid duplicating the channel mock.)

### CI
Add a lightweight step to `.github/workflows/build_and_test.yml` (in the existing
`test` job after the unit/widget run, or a small separate job):
`fvm flutter test integration_test/` — headless on ubuntu, no emulator. Keep the
main `flutter test` (which excludes `integration_test/` by default since
`flutter test` with no path runs `test/`).

## De-risking (spike first)

Implement in two steps so the headless-boot risk is isolated:
1. **Boot → login screen** — pump `App`, assert the login screen renders (proves
   the full app boots headless under the integration binding + mock setup). If
   the default `AppDependencies` is not mock-mode, pass a mock-mode `dependencies`
   to `App` (it accepts the parameter).
2. **Login → dashboard** — drive the credentials + submit, assert the
   dashboard/home renders.

## Verification

- `fvm flutter test integration_test/` green.
- `fvm flutter test` (the `test/` suite) still green and unchanged in count
  (it does not pick up `integration_test/`).
- `dart analyze` / `dart format` clean.
- CI step added and documented; `integration_test` dep is now genuinely used.
- `docs/testing-architecture.md` gets an "End-to-end" note + run command.

## Non-goals (YAGNI)

- One happy-path smoke only — no multi-flow / edge-case e2e.
- No on-device (`flutter drive`) CI — emulators are slow/flaky; headless is enough
  for a regression smoke.

## Acceptance

- `integration_test/app_smoke_test.dart` boots the app in mock mode and verifies
  login → dashboard; runs headless locally and in CI; `integration_test` dep used;
  documented. Closes #152.
