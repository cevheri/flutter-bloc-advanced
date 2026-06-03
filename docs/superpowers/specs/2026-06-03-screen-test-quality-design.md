# Screen Test Quality — Design (#168, scoped slice)

**Date:** 2026-06-03
**Issue:** #168 (screen behavior-test quality epic)
**Status:** Approved (design) — this spec covers the **correctness slice** (#1–3) +
brittle-text (#5) + convention doc. The epic's #6/#7 (mock rewrite, surface API)
and #8–11 (cosmetic) remain open in #168.

## Problem

Several screen behavior tests are green but don't actually verify the behavior
they claim. The systemic issue: `verify(() => bloc.add(any())).called(N)` with no
event-type matcher — and since each screen adds an init event on mount, a loose
`any()`/`greaterThan(0)` is satisfied even if the action under test (submit/search)
never fired. Plus a dead `MockUserRepository` and brittle `find.text('User')`.

## Goals

- Make submit/search/load verifications assert the **correct event type**, so a
  broken action fails the test.
- Remove the dead repository mock.
- De-brittle `find.text('User')` assertions.
- Document the screen-test convention so this class of false-confidence test
  doesn't recur.
- No behavior change to assertions' intent; suite stays green.

## Non-goals (kept in epic #168)

- #6 rewrite `user_editor`'s mock (re-implements the bloc state machine) to
  `whenListen`.
- #7 unify the surface-size API.
- #8–11 cosmetic (naming, `addTearDown` placement, redundant `pump`).

## Fixes

### 1. Event-type-matched verifications (7 sites, 4 files)

Existing mocktail fallbacks already cover `any(that: isA<…>())` (the base-type
fallback is registered), so no new fallback registration is needed.

| File:site | Test intent | Current | New |
| --- | --- | --- | --- |
| `account_screen_test.dart:201` | Save submits | `add(any()).called(2)` | `add(any(that: isA<AccountSubmitEvent>())).called(1)` |
| `forgot_password_screen_test.dart:201` | Send email | `add(any()).called(1)` | `add(any(that: isA<ForgotPasswordEmailChanged>())).called(1)` |
| `user_list_screen_test.dart:185` | Search dispatched | `add(any()).called(greaterThan(0))` | `add(any(that: isA<UserListSearch>())).called(1)` |
| `user_editor_screen_test.dart:161` | Edit-mode fetch | `add(any()).called(1)` | `add(any(that: isA<UserEditorFetch>())).called(1)` |
| `user_editor_screen_test.dart:253` | Invalid form blocks submit | `add(any()).called(1)` | `verifyNever(() => …add(any(that: isA<UserEditorSubmit>())))` |
| `user_editor_screen_test.dart:296` | Valid form submits | `add(any()).called(greaterThan(0))` | `add(any(that: isA<UserEditorSubmit>())).called(1)` |
| `user_editor_screen_test.dart:118` | Create-mode renders empty form | `add(any()).called(1)` | **remove** — it asserts the incidental init event, not the render; the field-key assertions are the real test |

Event classes: `AccountSubmitEvent`/`AccountFetchEvent`,
`ForgotPasswordEmailChanged` (the only forgot-password event; submit dispatches
it), `UserListSearch`, `UserEditorFetch`/`UserEditorSubmit`/`UserEditorReset`.

After each change, run the file: a correctly-failing test (e.g. if the action
didn't fire) must now fail; the suite stays green because the actions DO fire.

### 2. Remove dead `MockUserRepository`

`user_editor_screen_test.dart` creates `mockUserRepository` and stubs
`retrieve()`, but never injects it (the screen is driven by `mockUserBloc`).
Delete the field, its `setUp` init, and the `retrieve` stub (lines ~25, 30, 136).

### 3. De-brittle `find.text('User')`

The fixture `lastName: 'User'` collides with common tokens, making
`find.text('User'), findsOneWidget` fragile in `user_editor_screen_test.dart`
(edit/view) and `user_list_screen_test.dart`. Change the fixture `lastName` to a
unique value (e.g. `'Tester'`) and update the corresponding `find.text(...)`
assertions. (Login/firstName/email are already unique.)

### 4. Document the convention

Add to `docs/testing-architecture.md` (Widget tests subsection):

- Verify an action by **event type**: `verify(() => bloc.add(any(that: isA<XEvent>()))).called(1)`
  — not `any()` / `greaterThan(0)` (screens add an init event on mount, so a loose
  verify is satisfied even if the action never fired).
- Don't keep a repository mock that isn't injected — screen tests drive the
  screen through its mock BLoC.
- Mock the BLoC's state stream with `whenListen` + a seeded state; don't
  re-implement the bloc's state machine inside the `add` stub.
- Use unique fixture values so `findsOneWidget` is unambiguous.

## Verification

- The 6 rewritten verifications use `isA<…>()` matchers; the render-only verify is
  removed; `verifyNever` guards the invalid-submit case.
- No `MockUserRepository` / no `find.text('User')` brittleness in the two files.
- `grep verify(() => .*add(any())).called` in the four files → only type-matched
  forms remain.
- Full `flutter test` green; `dart analyze` / `dart format` clean.

## Acceptance

- 7 verify sites corrected (6 type-matched, 1 removed); dead repo removed; brittle
  text fixed; convention documented. Suite green. #168's #6/#7/#8–11 stay open.
