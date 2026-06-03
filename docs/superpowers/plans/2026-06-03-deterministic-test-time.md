# Deterministic Test Time Implementation Plan (#148)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove wall-clock dependence from the test suite — drive time-based logic with `fakeAsync`, stop using real-time `blocTest(wait:)` for mocked async, and use a fixed instant for arbitrary-value fixtures.

**Architecture:** `event_transformers_test` moves to `fakeAsync` (virtual time). `dynamic_form_bloc_test` drops the `wait:`/`Future.delayed` real waits (the mocked Dio responses resolve on microtasks; ordering is made explicit with `bloc.stream.firstWhere`). Arbitrary fixture timestamps use a shared `kTestInstant`. Legitimately relative/time-bracket tests are left untouched.

**Tech Stack:** Flutter 3.44.0, `flutter_test`, `bloc_test`, `fake_async` 1.3.3 (dev dep), `mocktail`, FVM. Run tests with `fvm flutter test`.

---

## Key facts

- The bloc's `stream` is a broadcast stream, so a `firstWhere` listener inside an
  `act` callback coexists with `blocTest`'s own collector.
- `dynamic_form_bloc` uses `restart()` / `dropConcurrent()` transformers — **no
  debounce**. Its test `wait:`s only cover mocked async settling.
- `fakeAsync`'s `async.elapse(d)` advances virtual time, running all timers and
  microtasks scheduled within `d` in order — instantly in real time.
- Baseline: full suite 1565 tests green (~31–36s wall, high variance).

## File structure

- Modify `test/shared/utils/event_transformers_test.dart` — Task 1 (fakeAsync).
- Modify `test/shared/dynamic_forms/application/dynamic_form_bloc_test.dart` — Task 2 (drop waits).
- Modify `test/mocks/fake_data.dart` + `test/features/users/presentation/pages/list_user_screen_test.dart` — Task 3 (fixed instant).
- Modify `docs/testing-architecture.md` — Task 4 (docs).

---

## Task 1: `event_transformers_test.dart` → fakeAsync

**Files:**
- Modify: `test/shared/utils/event_transformers_test.dart` (replace the 4 `blocTest` cases; keep the `_Event`/`_Run`/`_CounterBloc` scaffold)

- [ ] **Step 1: Replace the imports + `main()` body**

Keep the top scaffold (`_Event`, `_Run`, `_CounterBloc`) exactly as-is. Change the
`bloc_test` import to `fake_async`, and replace the whole `void main() { ... }`
with the version below. Resulting import block:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';
import 'package:flutter_test/flutter_test.dart';
```

(Remove `import 'package:bloc_test/bloc_test.dart';` — no longer used.)

New `main()`:

```dart
void main() {
  group('EventTransformers.dropConcurrent', () {
    test('a second event added while the first handler is running is dropped', () {
      fakeAsync((async) {
        final bloc = _CounterBloc(transformer: EventTransformers.dropConcurrent());
        final states = <int>[];
        final sub = bloc.stream.listen(states.add);

        bloc
          ..add(_Run())
          ..add(_Run()); // dropped: previous handler is still running.

        async.elapse(const Duration(seconds: 1)); // past handlerDelay; instant in virtual time

        expect(states, [1]);
        expect(bloc.runs, 1);

        sub.cancel();
        bloc.close();
      });
    });
  });

  group('EventTransformers.debounceRestartable', () {
    test('rapid bursts collapse to a single handler invocation after debounce', () {
      fakeAsync((async) {
        final bloc = _CounterBloc(
          transformer: EventTransformers.debounceRestartable(const Duration(milliseconds: 50)),
        );
        final states = <int>[];
        final sub = bloc.stream.listen(states.add);

        bloc
          ..add(_Run())
          ..add(_Run())
          ..add(_Run());

        async.elapse(const Duration(seconds: 1)); // past debounce window + handlerDelay

        expect(states, [1]);
        expect(bloc.runs, 1);

        sub.cancel();
        bloc.close();
      });
    });
  });

  group('EventTransformers.restart', () {
    test('a new event cancels the in-flight handler so only the latest emits', () {
      fakeAsync((async) {
        final bloc = _CounterBloc(transformer: EventTransformers.restart());
        final states = <int>[];
        final sub = bloc.stream.listen(states.add);

        bloc
          ..add(_Run())
          ..add(_Run()); // cancels the prior handler before it emits.

        async.elapse(const Duration(seconds: 1));

        // Two handler invocations start, but only the latest reaches emit(): 1.
        expect(states, [1]);

        sub.cancel();
        bloc.close();
      });
    });
  });

  group('EventTransformers.queue', () {
    test('events are processed strictly one-at-a-time in arrival order', () {
      fakeAsync((async) {
        final bloc = _CounterBloc(transformer: EventTransformers.queue());
        final states = <int>[];
        final sub = bloc.stream.listen(states.add);

        bloc
          ..add(_Run())
          ..add(_Run())
          ..add(_Run());

        async.elapse(const Duration(seconds: 1)); // 3 × handlerDelay, sequential

        // None dropped, none cancelled — three emissions in order.
        expect(states, [1, 2, 3]);
        expect(bloc.runs, 3);

        sub.cancel();
        bloc.close();
      });
    });
  });
}
```

- [ ] **Step 2: Run the file**

Run: `fvm flutter test test/shared/utils/event_transformers_test.dart -r compact 2>&1 | tail -4`
Expected: `All tests passed!` (4 tests).

If a test does not see the expected emissions, the bloc's event ingestion needs a
microtask turn before/after elapsing: add `async.flushMicrotasks();` immediately
after the `bloc.add(...)` calls and again after `async.elapse(...)`. Do NOT
re-introduce real-time waits. The assertions above are correct (they match the
current passing tests), so tune only the elapse/flush sequence until green.

- [ ] **Step 3: Confirm no wall-clock dependence**

Run: `fvm flutter test test/shared/utils/event_transformers_test.dart` and confirm
it completes in well under a second of test time (no `wait:` remains).

- [ ] **Step 4: Commit**

```bash
git add test/shared/utils/event_transformers_test.dart
git commit -m "test: drive event transformer tests with fakeAsync (deterministic) (#148)"
```

---

## Task 2: `dynamic_form_bloc_test.dart` → drop real-time waits

**Files:**
- Modify: `test/shared/dynamic_forms/application/dynamic_form_bloc_test.dart`

The file has 13 `wait: const Duration(milliseconds: 300)` lines and 6
`await Future<void>.delayed(const Duration(milliseconds: 100|150))` sequencing
delays (around lines 363, 383, 405, 424, 445, 522 — line numbers drift as edits
are made, so locate by content).

- [ ] **Step 1: Remove every `wait:` that only covers mocked async**

Delete each `wait: const Duration(milliseconds: 300),` line in the `blocTest`
cases. (These wait for a mocked Dio response that resolves on a microtask;
`blocTest` already awaits the bloc's state stream.)

- [ ] **Step 2: Replace each sequencing `Future.delayed` with a state wait**

Every sequencing delay is "wait for the Load/LoadBundle to finish before adding
the next event." Replace the delay with a wait on the loaded state. Pattern
(applies to all 6 sites — both `DynamicFormLoadEvent` and `DynamicFormLoadBundleEvent`
emit `DynamicFormLoaded`):

Before:
```dart
act: (bloc) async {
  bloc.add(const DynamicFormLoadEvent('no_action_form'));
  await Future<void>.delayed(const Duration(milliseconds: 100));
  bloc.add(const DynamicFormSubmitEvent({'name': 'John'}));
},
```
After:
```dart
act: (bloc) async {
  bloc.add(const DynamicFormLoadEvent('no_action_form'));
  await bloc.stream.firstWhere((s) => s is DynamicFormLoaded);
  bloc.add(const DynamicFormSubmitEvent({'name': 'John'}));
},
```

For sites that re-stub between load and the next event (lines ~383, ~405, ~424,
~522), keep the `stub.stub...` call in the same position (after the `firstWhere`,
before the next `add`). For the LoadBundle site (~522), the predicate is the same
`(s) => s is DynamicFormLoaded`.

- [ ] **Step 3: Run the file**

Run: `fvm flutter test test/shared/dynamic_forms/application/dynamic_form_bloc_test.dart -r compact 2>&1 | tail -5`
Expected: `All tests passed!` (same test count as before).

If any test now misses a trailing emission (e.g. a Submit state emitted after
`act` returns), add a single `await bloc.stream.firstWhere((s) => s is <ExpectedFinalState>);`
at the end of that `act` rather than a timed `wait:`. If a transformer needs one
event-loop turn, use `await Future<void>.delayed(Duration.zero)` (a microtask hop,
not wall-clock). Never restore a millisecond `wait:`.

- [ ] **Step 4: Confirm no real-time waits remain**

Run: `grep -nE "wait: const Duration\(milliseconds: [1-9]|Future<void>.delayed\(const Duration\(milliseconds: [1-9]" test/shared/dynamic_forms/application/dynamic_form_bloc_test.dart`
Expected: no output (only `Duration.zero` delays, if any, are acceptable).

- [ ] **Step 5: Commit**

```bash
git add test/shared/dynamic_forms/application/dynamic_form_bloc_test.dart
git commit -m "test: drop real-time waits in dynamic form bloc tests; sequence on state (#148)"
```

---

## Task 3: fixed instant for arbitrary-value fixtures

**Files:**
- Modify: `test/mocks/fake_data.dart`
- Modify: `test/features/users/presentation/pages/list_user_screen_test.dart`

- [ ] **Step 1: Add the shared constant to `fake_data.dart`**

Add near the top of `test/mocks/fake_data.dart` (after the existing
`final DateTime createdDate = DateTime(2024, 1, 1);`):

```dart
/// Fixed instant for fixtures whose timestamp value is arbitrary. Use this
/// instead of DateTime.now() so a fixture never depends on wall-clock time.
final DateTime kTestInstant = DateTime.utc(2024, 1, 1, 12);
```

- [ ] **Step 2: Replace `DateTime.now()` in the list-user fixture**

In `test/features/users/presentation/pages/list_user_screen_test.dart`, replace
`createdDate: DateTime.now()` and `lastModifiedDate: DateTime.now()` (around lines
134/136) with `createdDate: kTestInstant` and `lastModifiedDate: kTestInstant`.
Ensure the file imports `kTestInstant` — add `import '../../../../mocks/fake_data.dart';`
if not already present (verify the relative depth: the file is at
`test/features/users/presentation/pages/`, so `../../../../mocks/fake_data.dart`).

- [ ] **Step 3: Audit the remaining `DateTime.now()` sites (no code change)**

Run: `grep -rn "DateTime.now()" test/ --include='*.dart'`
Confirm each remaining site is one of: relative expiry (`.add`/`.subtract`),
a `before`/`after` range-bracket assertion, or `idle_timeout_observer_test`
(fakeAsync). These are correct — leave them. The only conversions are the
list-user fixtures from Step 2.

- [ ] **Step 4: Run affected file**

Run: `fvm flutter test test/features/users/presentation/pages/list_user_screen_test.dart -r compact 2>&1 | tail -3`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add test/mocks/fake_data.dart test/features/users/presentation/pages/list_user_screen_test.dart
git commit -m "test: use a fixed instant for arbitrary-value fixtures (#148)"
```

---

## Task 4: document the determinism conventions

**Files:**
- Modify: `docs/testing-architecture.md` (the "Determinism & known gaps" section)

- [ ] **Step 1: Update the section**

Replace the existing "Determinism & known gaps" bullet list content with:

```markdown
- **Time:** use `fakeAsync` for time-based logic (timers, debounce, timeouts).
  `event_transformers_test.dart` is the reference — it drives the bloc inside
  `fakeAsync` and advances virtual time with `async.elapse(...)`, with no
  wall-clock dependency. `idle_timeout_observer_test.dart` uses the same approach.
- **Mocked async:** do not use real-time `blocTest(wait:)` to "let a mock settle"
  — `blocTest` already awaits the bloc's state stream. Sequence dependent events
  with `await bloc.stream.firstWhere((s) => s is <State>)`, not a millisecond delay.
- **Fixtures:** use the fixed `kTestInstant` (`test/mocks/fake_data.dart`) for any
  fixture timestamp whose exact value no assertion depends on — never `DateTime.now()`.
- **Goldens:** there are no golden/visual-regression tests yet (issue #135). The
  bootstrap is where font loading will be wired when they land.
- **Tags/presets:** there is no `dart_test.yaml` tagging scheme yet (issue #154).
```

(This removes the prior #148 "still uses real-time `blocTest(wait:)`" item.)

- [ ] **Step 2: Commit**

```bash
git add docs/testing-architecture.md
git commit -m "docs: document fakeAsync + no-real-wait + fixed-instant conventions (#148)"
```

---

## Task 5: full verification + measurement

- [ ] **Step 1: Full suite**

Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -3`
Expected: `All tests passed!` (1565, unchanged count).

- [ ] **Step 2: Analyze + format**

Run: `fvm dart analyze` → `No issues found!`
Run: `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0 (if it reformats, `git add -A`).

- [ ] **Step 3: Measure the targeted files before/after (sanity)**

Run: `/usr/bin/time -v fvm flutter test test/shared/utils/event_transformers_test.dart test/shared/dynamic_forms/application/dynamic_form_bloc_test.dart -r compact 2>&1 | grep -E "Elapsed|All tests"`
Expected: noticeably lower than the ~7.3s baseline for these two files.

- [ ] **Step 4: Commit any formatting**

```bash
git add -A && git commit -m "test: deterministic time finalize (#148)" || echo "nothing to commit"
```

---

## Self-review notes

- **Spec coverage:** Part A → Task 1; Part B → Task 2; Part C → Task 3; Part D →
  Task 4; verification → Task 5. All covered.
- **No real-wait regressions:** Tasks 1 & 2 each end with a grep/behavioral check
  forbidding millisecond waits; fallback guidance uses `Duration.zero`/state
  waits, never timed waits.
- **Type consistency:** `DynamicFormLoaded`, `DynamicFormSubmitEvent`,
  `DynamicFormLoadEvent`, `DynamicFormLoadBundleEvent`, `_CounterBloc`,
  `EventTransformers.{dropConcurrent,debounceRestartable,restart,queue}`,
  `kTestInstant` used consistently.
- **No placeholders:** full converted source for Task 1; concrete before/after for
  Task 2; exact constant + edits for Task 3.
