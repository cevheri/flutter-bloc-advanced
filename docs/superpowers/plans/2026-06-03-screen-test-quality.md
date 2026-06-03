# Screen Test Quality Fixes Implementation Plan (#168 slice)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make screen-test action verifications assert the correct event type (so a broken submit/search fails the test), remove a dead repository mock, de-brittle `find.text('User')`, and document the convention. Correctness slice of epic #168.

**Architecture:** Edit 4 screen test files (`user_editor`, `account`, `forgot_password`, `user_list`) + `docs/testing-architecture.md`. Each loose `verify(() => bloc.add(any())).called(N)` becomes a type-matched `verify(() => bloc.add(any(that: isA<XEvent>()))).called(1)` (existing mocktail fallbacks cover the base type, so no new registration). Line numbers may drift — locate by content.

**Tech Stack:** Flutter 3.44.0, `flutter_test`, `bloc_test`, `mocktail`, FVM.

---

## Key facts

- Each screen adds an init event on mount, so `verify(add(any()))` is satisfied even if the action never fired → must match the event TYPE.
- Event classes: `AccountSubmitEvent` / `AccountFetchEvent`; `ForgotPasswordEmailChanged` (the only forgot-password event; submit dispatches it); `UserListSearch`; `UserEditorFetch` / `UserEditorSubmit` / `UserEditorReset`.
- `any(that: isA<XEvent>())` reuses the registered base-type fallback (e.g. `UserEditorReset` for `UserEditorEvent`) — `verify(add(any()))` already works in these files, so `any(that:)` works too. If a verify ever errors on a missing fallback, register it in `test/mocks/mock_classes.dart`'s `registerAllFallbackValues()`.

---

## Task 1: `user_editor_screen_test.dart`

**Files:**
- Modify: `test/features/users/presentation/pages/user_editor_screen_test.dart`

- [ ] **Step 1: Remove the dead `MockUserRepository`**

Delete the field declaration (`late MockUserRepository mockUserRepository;`), its
`setUp` initialization (`mockUserRepository = MockUserRepository();`), and the
unused stub in the Edit-mode test
(`when(() => mockUserRepository.retrieve(userId)).thenAnswer((_) async => const Success(mockUser));`).
The screen is driven by `mockUserBloc`; the repository mock is never injected.
(If `Success`/`MockUserRepository` imports become unused, remove them.)

- [ ] **Step 2: Fix the 4 verify sites**

- "Create Mode - Should render empty form" (~line 118): **remove**
  `verify(() => mockUserBloc.add(any())).called(1);` — it asserts the incidental
  init event, not the render. The `find.byKey(...)` field assertions remain the test.
- "Edit Mode - Should load and display user data" (~line 161): replace
  `verify(() => mockUserBloc.add(any())).called(1);` with
  `verify(() => mockUserBloc.add(any(that: isA<UserEditorFetch>()))).called(1);`
- "Create Mode - Should validate form before submit" (~line 253): replace
  `verify(() => mockUserBloc.add(any())).called(1);` with
  `verifyNever(() => mockUserBloc.add(any(that: isA<UserEditorSubmit>())));`
  (an invalid form must NOT dispatch a submit).
- "Create Mode - Should submit valid form" (~line 296): replace
  `verify(() => mockUserBloc.add(any())).called(greaterThan(0));` with
  `verify(() => mockUserBloc.add(any(that: isA<UserEditorSubmit>()))).called(1);`

- [ ] **Step 3: De-brittle `find.text('User')`**

In both fixtures (Edit-mode `mockUser` ~line 130 and View-mode `mockUser` ~line 173),
change `lastName: 'User'` → `lastName: 'Tester'`. Update the corresponding
assertions `expect(find.text('User'), findsOneWidget);` (~lines 158, 209) →
`expect(find.text('Tester'), findsOneWidget);`.

- [ ] **Step 4: Run + analyze/format**

Run: `fvm flutter test test/features/users/presentation/pages/user_editor_screen_test.dart -r compact 2>&1 | tail -3` → `All tests passed!`.
Run: `fvm dart analyze test/features/users/presentation/pages/user_editor_screen_test.dart` → No issues found.
Run: `fvm dart format test/features/users/presentation/pages/user_editor_screen_test.dart --line-length=120`.

- [ ] **Step 5: Commit**

```bash
git add test/features/users/presentation/pages/user_editor_screen_test.dart
git commit -m "test: type-matched verify + drop dead repo mock + unique fixture in user_editor (#168)"
```

---

## Task 2: account / forgot_password / user_list

**Files:**
- Modify: `test/features/account/presentation/pages/account_screen_test.dart`
- Modify: `test/features/auth/presentation/pages/forgot_password_screen_test.dart`
- Modify: `test/features/users/presentation/pages/user_list_screen_test.dart`

- [ ] **Step 1: account (~line 201)** — the "submit valid form" / Save test. Replace
  `verify(() => mockAccountBloc.add(any())).called(2);` with
  `verify(() => mockAccountBloc.add(any(that: isA<AccountSubmitEvent>()))).called(1);`
  (Add the `account_event.dart` import if `AccountSubmitEvent` isn't in scope.)

- [ ] **Step 2: forgot_password (~line 201)** — "send email Successful". Replace
  `verify(() => forgotPasswordBloc.add(any())).called(1);` with
  `verify(() => forgotPasswordBloc.add(any(that: isA<ForgotPasswordEmailChanged>()))).called(1);`
  (Import `forgot_password_event.dart` if needed.)

- [ ] **Step 3: user_list (~line 185)** — "handles search button tap". Replace
  `verify(() => mockUserBloc.add(any())).called(greaterThan(0));` with
  `verify(() => mockUserBloc.add(any(that: isA<UserListSearch>()))).called(1);`
  Also de-brittle `find.text('User')`: the `mockUsers` fixture `lastName: 'User'`
  (~line 134) → `lastName: 'Tester'`, and the assertion `find.text('User')` (~line
  155) → `find.text('Tester')`.

- [ ] **Step 4: Run + analyze/format**

Run: `fvm flutter test test/features/account/presentation/pages/account_screen_test.dart test/features/auth/presentation/pages/forgot_password_screen_test.dart test/features/users/presentation/pages/user_list_screen_test.dart -r compact 2>&1 | tail -3` → `All tests passed!`.
Run: `fvm dart analyze` → No issues found; `fvm dart format <the 3 files> --line-length=120`.

If a `verify(any(that:))` errors with a missing fallback, add the matching
`registerFallbackValue(...)` in `test/mocks/mock_classes.dart` and re-run.

- [ ] **Step 5: Commit**

```bash
git add test/features/account/presentation/pages/account_screen_test.dart test/features/auth/presentation/pages/forgot_password_screen_test.dart test/features/users/presentation/pages/user_list_screen_test.dart
git commit -m "test: type-matched verify (account/forgot/user_list) + unique fixture (#168)"
```

---

## Task 3: document the convention

**Files:**
- Modify: `docs/testing-architecture.md` (Widget tests subsection)

- [ ] **Step 1:** After the Widget-tests example/bullets, add:

```markdown
**Verifying actions:** assert the dispatched event **by type** —
`verify(() => bloc.add(any(that: isA<XEvent>()))).called(1)` — not `any()` /
`called(greaterThan(0))`. Screens add an init event on mount, so a loose
`verify(add(any()))` is satisfied even if the action under test never fired
(false-confidence). For "must NOT happen" cases use
`verifyNever(() => bloc.add(any(that: isA<XEvent>())))`.

**Other screen-test rules:** don't keep a repository mock that isn't injected
(screen tests drive the screen through its mock BLoC); prefer `whenListen` + a
seeded state over re-implementing the bloc's state machine inside an `add` stub;
use unique fixture values so `findsOneWidget` is unambiguous.
```

- [ ] **Step 2: Commit**

```bash
git add docs/testing-architecture.md
git commit -m "docs: screen-test verify-by-event-type convention (#168)"
```

---

## Task 4: Full verification

- [ ] **Step 1:** `grep -rn "add(any())).called\|called(greaterThan(0))" test/features --include='*_test.dart' | grep -v golden` → no loose `add(any())` verifications remain (only `any(that: isA<…>())`).
- [ ] **Step 2:** `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -2` → `All tests passed!`.
- [ ] **Step 3:** `fvm dart analyze` → clean; `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0.
- [ ] **Step 4 (if formatting):** `git add -A && git commit -m "test: screen-test quality finalize (#168)" || echo "nothing to commit"`

---

## Self-review notes

- **Spec coverage:** 7 verify sites (Tasks 1–2), dead repo (Task 1), brittle text
  (Tasks 1–2), convention doc (Task 3), verification (Task 4). #6/#7/#8–11 stay in
  the epic.
- **No placeholders:** exact per-site before/after + event types; fixture/text
  changes specified; fallback fallback noted.
- **Consistency:** `any(that: isA<XEvent>())` + `.called(1)` / `verifyNever`
  pattern uniform across all sites.
