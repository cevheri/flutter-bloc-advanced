# Screen Test Quality Tail (#168 #6–#11) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Finish epic #168 — replace the user_editor mock state-machine with `whenListen`, unify the surface-size API, and clean up naming / nav assertion / teardown placement / redundant pumps. Closes #168.

**Architecture:** Two files. Preserve the PR-#171 event-type `verify`/`verifyNever` assertions exactly — only change the state source (`whenListen`) and cleanups.

**Tech Stack:** Flutter 3.44.0, `flutter_test`, `bloc_test` (`whenListen`), `mocktail`, FVM.

---

## Task 1: `user_editor_screen_test.dart` (#6 + #7 + #11)

**File:** `test/features/users/presentation/pages/user_editor_screen_test.dart`

- [ ] **Step 1 (#6 — whenListen):** For each of the 5 tests, replace the `StreamController<UserEditorState>` + `when(() => mockUserBloc.stream).thenAnswer((_) => controller.stream)` + `when(() => mockUserBloc.add(any())).thenAnswer((inv) { emit by event })` pattern with `bloc_test`'s `whenListen`:
  - `whenListen(mockUserBloc, Stream.fromIterable([<the states that test scripts>]), initialState: <initial state>);`
  - Keep `when(() => mockUserBloc.state).thenReturn(<initial/seeded state>)` where the screen reads `.state` synchronously.
  - Remove the `StreamController` declarations and their `await controller.close()` calls.
  - Per test, the scripted states are what the old `add().thenAnswer` emitted, e.g.:
    - Edit-mode load → `Stream.fromIterable([const UserEditorLoading(), UserEditorLoaded(data: mockUser)])`, `initialState: const UserEditorInitial()`.
    - View-mode → `initialState: UserEditorLoaded(data: mockUser)` (already seeded), stream `const Stream.empty()`.
    - Create-mode render / validate / submit → `initialState: const UserEditorInitial()`, stream `const Stream.empty()` (no state change needed; the test asserts on `add(...)`).
  - **Do NOT change the `verify(...)` / `verifyNever(...)` assertions** from PR #171 — the screen still dispatches events; only the state source changed.
  - Keep `mockAuthorityBloc` setup as-is.
- [ ] **Step 2 (#7 — surface API):** In the "submit valid form" test, replace `await tester.binding.setSurfaceSize(const Size(1200, 800));` with `tester.view.physicalSize = const Size(1200, 800); tester.view.devicePixelRatio = 1.0; addTearDown(tester.view.reset);` and delete the trailing `await tester.binding.setSurfaceSize(null);`.
- [ ] **Step 3 (#11 — redundant pump):** Remove the bare `await tester.pump();` lines that immediately precede `await tester.pumpAndSettle();` (keep the `pumpAndSettle()`).
- [ ] **Step 4:** Run: `fvm flutter test test/features/users/presentation/pages/user_editor_screen_test.dart -r compact 2>&1 | tail -4` → `All tests passed!` (same count, PR-#171 verifies still pass). `fvm dart analyze <file>` clean; `fvm dart format <file> --line-length=120`.
- [ ] **Step 5:** Commit: `git add -A && git commit -m "test: user_editor uses whenListen; unify surface API; drop redundant pumps (#168)"`

If a converted test fails because a state the screen needs no longer arrives, add it to the `Stream.fromIterable([...])` (or set `initialState`). If `whenListen` requires a registered fallback or specific import, add `import 'package:bloc_test/bloc_test.dart';` (already used by mock_classes). Report any per-test state sequence you had to adjust.

---

## Task 2: `user_list_screen_test.dart` (#8 + #9 + #10)

**File:** `test/features/users/presentation/pages/user_list_screen_test.dart`

- [ ] **Step 1 (#8 — naming):** `group('ListUserScreen Tests', ...)` → `group('UserListScreen Tests', ...)`; `testWidgets('renders ListUserScreen correctly', ...)` → `testWidgets('renders the user list correctly', ...)`. Leave `find.byType(ListUserScreen)` references (the inner widget class is real).
- [ ] **Step 2 (#9 — strengthen create-nav assertion):** In `buildTestableWidget`, change the `/user/new` route builder from `Scaffold(body: SizedBox.shrink())` to `Scaffold(body: Text('create-route'))`. In the "handles create button tap" test, replace `expect(find.byType(ListUserScreen), findsNothing);` with `expect(find.text('create-route'), findsOneWidget);` (asserts we navigated TO the create route, not merely away).
- [ ] **Step 3 (#10 — addTearDown placement):** In the "handles screen size responsiveness" test, move `addTearDown(tester.view.reset);` from the end of the test to immediately after the first `tester.view.physicalSize = const Size(1200, 800);` (+ its `devicePixelRatio`), matching the other tests.
- [ ] **Step 4:** Run: `fvm flutter test test/features/users/presentation/pages/user_list_screen_test.dart -r compact 2>&1 | tail -4` → `All tests passed!`. `fvm dart analyze <file>` clean; `fvm dart format <file> --line-length=120`.
- [ ] **Step 5:** Commit: `git add -A && git commit -m "test: user_list naming + assert create-route navigation + addTearDown placement (#168)"`

---

## Task 3: Doc + full verification

- [ ] **Step 1 (doc):** In `docs/testing-architecture.md`, extend the screen-test "Other screen-test rules" note (or the Pumping note) with: "Use `tester.view.physicalSize` + `addTearDown(tester.view.reset)` to size the test surface (not `binding.setSurfaceSize`), for one consistent API." (One sentence.)
- [ ] **Step 2:** `grep -rn "setSurfaceSize\|add(any())).thenAnswer\|ListUserScreen Tests" test/features/users/presentation/pages/*_test.dart` → no `setSurfaceSize`, no mock state-machine `add().thenAnswer`, no old group name.
- [ ] **Step 3:** `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -2` → `All tests passed!`. `fvm dart analyze` clean; `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0.
- [ ] **Step 4:** Commit: `git add -A && git commit -m "docs: surface-size API convention; #168 tail finalize (#168)"`

---

## Self-review notes
- **Spec coverage:** #6/#7/#11 (Task 1), #8/#9/#10 (Task 2), doc + verify (Task 3).
- **Preserve:** PR-#171 event-type verifies must stay green after the whenListen swap — Task 1 Step 1 calls this out explicitly.
- **No placeholders:** per-test whenListen state sequences specified; exact route/marker/assertion changes given.
