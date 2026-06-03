# pumpAndSettle Hygiene + Convention — Design (#151)

**Date:** 2026-06-03
**Issue:** #151 (test-infrastructure audit follow-up)
**Status:** Approved (design)

## Problem

The suite has 191 `pumpAndSettle` calls (non-golden). All pass today, so nothing
hangs — this is preventive + a misuse cleanup, not a live bug fix. Two concrete
issues:

1. **Misused `pumpAndSettle(Duration)` (8 calls).** Flutter's
   `pumpAndSettle([Duration duration = 100ms, EnginePhase, Duration timeout = 10min])`
   takes the **per-pump interval** as its first arg — **not** a timeout. Several
   calls pass `Duration(seconds: 5)` / `seconds: 1` / `ms: 1000`, clearly
   intending a timeout. They pass (the UI still settles, just stepped in coarse
   intervals) but the intent is wrong and the coarse stepping can mask or shift
   timing.
2. **No documented convention** for `pumpAndSettle` vs `pump(Duration)` vs (in
   goldens) `pumpBeforeTest: pumpOnce`. Golden Phase 1 already proved that
   continuously-animating widgets (shimmer, indeterminate spinner) never settle
   and hang `pumpAndSettle`.

## Goals

- Fix the 8 misused `pumpAndSettle(Duration)` calls to correct usage.
- Audit the handful of widget tests that pump loading/animated states; harden any
  that `pumpAndSettle` a continuously-animating state.
- Document the convention so contributors don't reintroduce either mistake.
- No behavior change; suite stays green.

## Non-goals (YAGNI)

- Do **not** convert the 183 bare `pumpAndSettle()` calls — they pass and settle.
  Touch only genuinely-misused or genuinely-risky calls.

## Design

### 1. Fix the 8 `pumpAndSettle(Duration)` calls

Sites:
- `test/features/dashboard/presentation/pages/home_screen_test.dart:36` `(seconds: 5)`
- `test/features/auth/presentation/pages/change_password_screen_test.dart:280` `(seconds: 1)`
- `test/features/users/presentation/pages/user_editor_screen_test.dart:153` `(seconds: 1)`
- `test/features/auth/presentation/pages/forgot_password_screen_test.dart:161` `(ms: 1000)`, `:180` `(seconds: 5)`, `:198/:219/:238` `(seconds: 1)`

Per call, choose the correct form:
- If the UI settles on its own → bare `await tester.pumpAndSettle();`.
- If the test waits for a **specific, known delay** (a mocked async + a snackbar
  with a display duration, a debounce) → `await tester.pump(const Duration(...))`
  with the real delay, optionally followed by a bare `pumpAndSettle()`.
- Never keep the interval-as-timeout form.

Each change is verified by re-running its file (must stay green); if a call was
genuinely masking a non-settling animation, switch to `pump(Duration)`.

### 2. Audit animation-risk widget tests

Files that pump a loading/animated state:
`login_otp_email_widget_test.dart`, `submit_button_widget_test.dart`,
`account_screen_test.dart`, `user_extended_info_page_test.dart`,
`dynamic_form_page_test.dart`, `user_editor_screen_test.dart`.

For each: confirm no bare `pumpAndSettle` is run while an indeterminate
`CircularProgressIndicator` (or similar) is on screen. They pass today, so the
spinner must currently resolve before the settle; document/leave those. If any
relies on a near-timeout settle, switch that call to `pump(Duration)`.

### 3. Document the convention

Add to `docs/testing-architecture.md` (and a one-line rule in `CLAUDE.md`):

- **`pumpAndSettle()`** — use when all animations are expected to **finish**
  (route/page transitions, one-shot reveal animations).
- **`pumpAndSettle(Duration)`** — the arg is the **per-pump interval, not a
  timeout** (timeout is a separate later parameter). Prefer the bare form; only
  pass an interval for a deliberate reason.
- **Continuous / indeterminate animations** (spinner, shimmer, looping) — never
  `pumpAndSettle` (it hangs to timeout). Use `pump(const Duration(...))` for a
  fixed frame, or in goldens `pumpBeforeTest: pumpOnce`.
- **Mocked async** — don't real-time-wait for it (see #148); rely on the bloc
  stream / `await ...firstWhere(...)`.

## Verification

- The 8 `pumpAndSettle(Duration)` sites use correct forms; each file green.
- `grep -rnE "pumpAndSettle\(const Duration" test/ --include='*_test.dart'`
  returns only deliberate, documented uses (ideally zero).
- Full `flutter test` green; `dart analyze` / `dart format` clean.
- Convention documented in `testing-architecture.md` + `CLAUDE.md`.

## Acceptance

- No `pumpAndSettle(Duration)` used as a pseudo-timeout.
- Animation-risk widget tests audited; any non-settling `pumpAndSettle` hardened.
- Convention documented. Suite green; 183 bare calls untouched.
