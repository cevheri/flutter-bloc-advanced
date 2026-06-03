# Deterministic Test Time — Design (#148)

**Date:** 2026-06-03
**Issue:** #148 (test-infrastructure audit follow-up)
**Status:** Approved (design)

## Problem & re-scoping

The audit issue (#148) flagged "20 real-time `blocTest(wait:)` + 51 `DateTime.now()`"
as flakiness/slowness debt. Investigation refined the picture:

- **`event_transformers_test.dart` (4 tests)** genuinely depend on real time: a
  debounce window (Timer) plus an 80 ms `Future.delayed` handler, asserted via
  `blocTest(wait: 250–350ms)`. These are the legitimate `fakeAsync` candidates.
- **`dynamic_form_bloc_test.dart` (13 `wait:` + 6 `Future.delayed`)** do NOT
  debounce — the bloc uses `restart()` / `dropConcurrent()` transformers, which
  add no delay. The waits exist to let a **mocked** Dio response (resolving on a
  microtask, i.e. effectively instantly) settle. `blocTest` already awaits the
  bloc's state stream, so these real-time waits are wasted (~10 × 300 ms ≈ 3 s of
  pure idle, plus 6 × 100–150 ms sequencing delays).
- **`DateTime.now()` (≈40 sites)** are mostly legitimate: relative expiry
  (`.add` / `.subtract`), `before`/`after` range-bracket assertions, and
  `idle_timeout_observer_test` (already `fakeAsync`). Only a couple of fixtures
  use `DateTime.now()` for a value no assertion depends on
  (`list_user_screen_test`), introducing pointless non-determinism.

## Goals

- Time-dependent logic asserts on **virtual** time (`fakeAsync`), not wall-clock.
- Tests that wait only for **mocked async** rely on `blocTest`'s stream awaiting,
  not arbitrary real-time `wait:`.
- Arbitrary-value fixtures use a **fixed instant**, not `DateTime.now()`.
- No assertion behavior changes; full suite stays green; suite gets faster and
  deterministic.

## Non-goals (YAGNI)

- No `package:clock` seam in **production** code — this is a test-only change.
- Do **not** touch correct relative-time / range-bracket tests (cache expiry,
  `before`/`after`, `idle_timeout`). Converting them adds risk for no value.

## Part A — `event_transformers_test.dart` → `fakeAsync`

Convert the 4 `blocTest(wait:)` cases to plain `test()` wrapped in `fakeAsync`,
driving the existing `_CounterBloc` manually. Pattern:

```dart
test('rapid bursts collapse to a single handler invocation after debounce', () {
  fakeAsync((async) {
    final bloc = _CounterBloc(
      transformer: EventTransformers.debounceRestartable(const Duration(milliseconds: 50)),
    );
    final states = <int>[];
    final sub = bloc.stream.listen(states.add);

    bloc..add(_Run())..add(_Run())..add(_Run());

    async.elapse(const Duration(milliseconds: 50)); // debounce window fires
    async.elapse(_CounterBloc.handlerDelay);         // 80ms handler completes
    async.flushMicrotasks();

    expect(states, [1]);
    expect(bloc.runs, 1);

    sub.cancel();
    bloc.close();
  });
});
```

- Keep the `_CounterBloc` scaffold and `handlerDelay` as-is.
- Each of the 4 groups (`dropConcurrent`, `debounceRestartable`, `restart`,
  `queue`) gets the same treatment with its own elapse amounts (e.g. `queue`
  elapses `3 × handlerDelay`).
- `async.elapse` advances both Timers (debounce) and `Future.delayed` (handler);
  interleave with `flushMicrotasks()` so bloc emissions settle.

This is the Flutter-standard way to test time-based stream logic and removes the
real-time `wait:`.

## Part B — `dynamic_form_bloc_test.dart` → drop wasted waits

For each `blocTest` whose `wait:` only covers a mocked async response:

1. Remove the `wait: const Duration(milliseconds: 300)` line.
2. For act callbacks that sequence Load → Submit via
   `await Future<void>.delayed(const Duration(milliseconds: 100/150))`, replace
   the delay with a deterministic wait on state:
   ```dart
   act: (bloc) async {
     bloc.add(const DynamicFormLoadEvent('no_action_form'));
     await bloc.stream.firstWhere((s) => s is DynamicFormLoaded);
     bloc.add(const DynamicFormSubmitEvent({'name': 'John'}));
   },
   ```
3. **Verification gate:** run the file after each change. If `blocTest` misses a
   late emission without `wait:`, do NOT restore a guessed duration — instead use
   the smallest deterministic mechanism (an explicit `await bloc.stream.firstWhere(...)`
   in `act`, or `bloc_test`'s built-in stream settling). Only if a transformer
   genuinely needs an event-loop turn, use `await Future<void>.delayed(Duration.zero)`
   (a microtask hop, not wall-clock time).

Net effect: removes ~3 s of idle waiting and makes ordering explicit rather than
timing-dependent.

## Part C — fixed instant for arbitrary fixtures

- Add a shared constant to `test/mocks/fake_data.dart`:
  ```dart
  /// Fixed instant for fixtures whose timestamp value is arbitrary — keeps
  /// tests deterministic (never use DateTime.now() for a value no assertion
  /// depends on).
  final DateTime kTestInstant = DateTime.utc(2024, 1, 1, 12);
  ```
- Replace `DateTime.now()` with `kTestInstant` in fixtures where the value is
  arbitrary: `test/features/users/presentation/pages/list_user_screen_test.dart`
  (`createdDate`, `lastModifiedDate`).
- Audit the remaining `DateTime.now()` sites; leave the legitimately relative /
  range-bracket ones untouched. Where a relative-time test reads as ambiguous,
  add a one-line `// intentionally relative to now` comment instead of changing it.

## Part D — documentation

Update the "Determinism & known gaps" section of `docs/testing-architecture.md`:
- `fakeAsync` for time-based logic (link `event_transformers_test` as the example).
- No real-time `wait:` for mocked async — rely on `blocTest` stream awaiting.
- Fixed instants (`kTestInstant`) for arbitrary-value fixtures.
- Remove #148 from the "not-yet-done" list once complete.

## Verification

- `dart format --set-exit-if-changed` clean; `dart analyze` clean.
- Full `flutter test` green (1565), no count change.
- Record wall-clock before/after for `event_transformers_test` +
  `dynamic_form_bloc_test` (expect a measurable drop).

## Acceptance

- No `blocTest(wait:)` with real durations remain for debounce or mocked-async
  settling (or each remaining one has a documented justification).
- `event_transformers_test` runs under `fakeAsync` with no wall-clock dependency.
- No `DateTime.now()` in arbitrary-value fixtures.
- Determinism conventions documented; suite green and faster.
