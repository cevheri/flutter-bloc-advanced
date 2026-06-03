# Screen Test Quality — Tail (#168 remaining) Design

**Date:** 2026-06-04
**Issue:** #168 (screen behavior-test quality epic) — the remaining items #6–#11.
**Status:** Approved (design). Completing this closes #168 (the correctness slice
#1–3/#5 shipped in PR #171).

## Scope (2 files: `user_editor_screen_test.dart`, `user_list_screen_test.dart`)

### #6 — Replace `user_editor`'s mock state-machine with `whenListen`
The 5 tests each use a `StreamController` + `when(() => mockUserBloc.add(any())).thenAnswer((inv) { emit states by event type })`, re-implementing the bloc inside the mock. Replace per test with `whenListen(mockUserBloc, Stream.fromIterable([<states>]), initialState: <state>)` + (where needed) `when(() => mockUserBloc.state).thenReturn(<state>)`. The screen still dispatches events, so the event-type `verify(...)`/`verifyNever(...)` assertions added in PR #171 keep working — only the **state source** changes from reactive-mock to a scripted stream. Drop the now-unused `StreamController`s and their `close()`s.

### #7 — Unify the surface-size API
`user_editor` uses `tester.binding.setSurfaceSize(const Size(1200, 800))` / `setSurfaceSize(null)` (one test); `user_list` uses `tester.view.physicalSize` + `devicePixelRatio` + `addTearDown(tester.view.reset)` (6 places). Standardize on `tester.view.physicalSize` everywhere — convert the one `user_editor` site to:
`tester.view.physicalSize = const Size(1200, 800); tester.view.devicePixelRatio = 1.0; addTearDown(tester.view.reset);` and remove the `setSurfaceSize(null)`.

### #8 — Naming (`user_list`)
`group('ListUserScreen Tests', ...)` → `group('UserListScreen Tests', ...)`; `testWidgets('renders ListUserScreen correctly', ...)` → `'renders the user list correctly'`. `find.byType(ListUserScreen)` references the real inner widget class — keep it (it exists); #9 handles the assertion itself.

### #9 — Strengthen the create-navigation assertion (`user_list`)
`expect(find.byType(ListUserScreen), findsNothing)` (passes if the screen disappears for any reason). Give the test router's create route a findable marker and assert we navigated **to** it:
- In `buildTestableWidget`, change the `/user/new` route builder body from `SizedBox.shrink()` to `Text('create-route')` (a Material ancestor exists via MaterialApp.router).
- Replace the assertion with `expect(find.text('create-route'), findsOneWidget);` (and optionally keep `find.byType(ListUserScreen), findsNothing`).

### #10 — `addTearDown` placement (`user_list`)
In the responsiveness test, the `addTearDown(tester.view.reset)` sits at the end; move it directly after the first `tester.view.physicalSize = ...` set, matching the other tests.

### #11 — Redundant `pump()` (`user_editor`)
Remove the bare `await tester.pump();` lines that immediately precede `await tester.pumpAndSettle();` (pumpAndSettle already pumps). Sites ~104–105, 146–147, 192–193, 230–231.

## Non-goals
None — this completes #168.

## Verification
- `user_editor_screen_test.dart` + `user_list_screen_test.dart` green individually.
- The PR-#171 event-type `verify`/`verifyNever` assertions still pass (whenListen must not break them).
- No `setSurfaceSize`, no `add(any())).thenAnswer` (mock state machine), no bare `pump(); pumpAndSettle();` pairs remain in these files.
- Full `flutter test` green; `dart analyze` / `dart format` clean.

## Acceptance
- #6–#11 done; #168 fully resolved (closes on merge). Suite green.
