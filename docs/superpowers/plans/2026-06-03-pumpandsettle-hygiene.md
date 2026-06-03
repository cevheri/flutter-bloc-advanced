# pumpAndSettle Hygiene Implementation Plan (#151)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 8 misused `pumpAndSettle(Duration)` calls (interval-as-pseudo-timeout) with correct forms, audit animation-risk widget tests, and document the `pumpAndSettle` vs `pump(Duration)` convention.

**Architecture:** All 8 sites were reviewed: each waits only for a self-settling render (a seeded state, a validation message, or a microtask-resolved mock) — none wait for a specific real-time delay — so each becomes a bare `await tester.pumpAndSettle();`. Then a quick audit of loading-state widget tests, then docs.

**Tech Stack:** Flutter 3.44.0, `flutter_test`, FVM.

---

## Background fact (drives the fix)

`pumpAndSettle([Duration duration = 100ms, EnginePhase phase, Duration timeout = 10min])`
— the first positional arg is the **per-pump interval**, NOT a timeout. Passing
`Duration(seconds: 5)` makes it step in 5s frames; it does not "wait up to 5s".
The 8 sites pass an interval intending a timeout; the correct form for a
self-settling render is the bare `pumpAndSettle()`.

---

## Task 1: Fix the 8 `pumpAndSettle(Duration)` calls

All 8 → bare `await tester.pumpAndSettle();` (reviewed: each follows a render
that settles on its own — no real-time delay to wait for).

**Files / sites:**
- `test/features/dashboard/presentation/pages/home_screen_test.dart:36` — `pumpAndSettle(const Duration(seconds: 5))` → `pumpAndSettle()` (after `buildHomeApp()`; shell settles).
- `test/features/auth/presentation/pages/change_password_screen_test.dart:280` — `pumpAndSettle(const Duration(seconds: 1))` → `pumpAndSettle()` (after submit tap).
- `test/features/users/presentation/pages/user_editor_screen_test.dart:153` — `pumpAndSettle(const Duration(seconds: 1))` → `pumpAndSettle()` (edit-mode load; mock resolves on a `Future.delayed(Duration.zero)`).
- `test/features/auth/presentation/pages/forgot_password_screen_test.dart` — five sites: `:161` `(ms: 1000)`, `:180` `(seconds: 5)`, `:198` `(seconds: 1)`, `:219` `(seconds: 1)`, `:238` `(seconds: 1)` → all `pumpAndSettle()`.

- [ ] **Step 1:** In each file, replace every `pumpAndSettle(const Duration(...))` with `pumpAndSettle()`. (Locate by content; line numbers may drift.) Confirm none remain:
  `grep -rnE "pumpAndSettle\(const Duration" test/ --include='*_test.dart' | grep -v golden` → empty.

- [ ] **Step 2:** Run the affected files:

`fvm flutter test test/features/dashboard/presentation/pages/home_screen_test.dart test/features/auth/presentation/pages/change_password_screen_test.dart test/features/users/presentation/pages/user_editor_screen_test.dart test/features/auth/presentation/pages/forgot_password_screen_test.dart -r compact 2>&1 | tail -3`
Expected: `All tests passed!`.

If a file now fails (a render that genuinely needed time), the right fix is an
explicit `await tester.pump(const Duration(...))` for that specific delay
followed by a bare `pumpAndSettle()` — NOT restoring the interval form. Report
any site that needed this.

- [ ] **Step 3:** `fvm dart analyze` → clean; `fvm dart format <the 4 files> --line-length=120`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "test: fix misused pumpAndSettle(Duration) interval-as-timeout calls (#151)"
```

---

## Task 2: Audit animation-risk widget tests

Confirm no bare `pumpAndSettle` runs while a continuously-animating /
indeterminate widget (e.g. `CircularProgressIndicator`) is on screen (that would
hang to the 10-min timeout if the spinner never resolves).

**Files to inspect:**
- `test/features/auth/presentation/widgets/login_otp_email_widget_test.dart`
- `test/shared/widgets/submit_button_widget_test.dart`
- `test/features/account/presentation/pages/account_screen_test.dart`
- `test/features/users/presentation/pages/user_extended_info_page_test.dart`
- `test/shared/dynamic_forms/presentation/pages/dynamic_form_page_test.dart`
- `test/features/users/presentation/pages/user_editor_screen_test.dart`

- [ ] **Step 1:** For each, find where a loading/spinner state is on screen and
  check the following pump. They pass today, so the spinner resolves before the
  settle (mock emits a terminal state) — in that case **leave it**. ONLY if a
  test pumps an indeterminate spinner that never resolves (relying on a coarse
  interval or near-timeout) convert that one call to `await tester.pump(const Duration(milliseconds: ...))`.
- [ ] **Step 2:** Record findings (which were fine, which were hardened). Run any
  file you changed; if none changed, no commit for this task.
- [ ] **Step 3 (if changes):** Commit

```bash
git add -A && git commit -m "test: harden pumpAndSettle on non-settling loading states (#151)"
```

---

## Task 3: Document the convention

**Files:**
- Modify: `docs/testing-architecture.md`
- Modify: `CLAUDE.md` (Testing section)

- [ ] **Step 1:** Add a "Pumping & animations" subsection to the Determinism area of `docs/testing-architecture.md`:

```markdown
### Pumping & animations

- **`pumpAndSettle()`** — use when all animations are expected to **finish**
  (route/page transitions, one-shot reveals).
- **`pumpAndSettle(Duration)`** — the argument is the **per-pump interval, not a
  timeout** (the timeout is a separate, later parameter). Prefer the bare form;
  pass an interval only for a deliberate, documented reason.
- **Continuous / indeterminate animations** (spinner, shimmer, looping) — never
  `pumpAndSettle` (it pumps until the 10-minute timeout). Use
  `pump(const Duration(...))` for a fixed frame; in goldens use
  `pumpBeforeTest: pumpOnce`.
- **Mocked async** — don't real-time-wait for it; rely on the bloc stream /
  `await bloc.stream.firstWhere(...)` (see the determinism notes above).
```

- [ ] **Step 2:** Add a one-line rule to the `## Testing` section of `CLAUDE.md`:

```markdown
- **Pumping:** `pumpAndSettle()` only when animations finish; its `Duration` arg
  is the per-pump interval (not a timeout) — prefer the bare form. For continuous
  animations (spinner/shimmer) use `pump(Duration)`, never `pumpAndSettle`.
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md docs/testing-architecture.md
git commit -m "docs: document pumpAndSettle vs pump(Duration) convention (#151)"
```

---

## Task 4: Full verification

- [ ] **Step 1:** `grep -rnE "pumpAndSettle\(const Duration" test/ --include='*_test.dart' | grep -v golden` → empty (or only a documented, justified site).
- [ ] **Step 2:** `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -2` → `All tests passed!`.
- [ ] **Step 3:** `fvm dart analyze` → clean; `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0.
- [ ] **Step 4 (if formatting):** `git add -A && git commit -m "test: pumpAndSettle hygiene finalize (#151)" || echo "nothing to commit"`

---

## Self-review notes

- **Spec coverage:** 8 misused calls (Task 1), animation-risk audit (Task 2),
  convention docs (Task 3), verification (Task 4).
- **YAGNI:** the 183 bare `pumpAndSettle()` calls are untouched.
- **No placeholders:** exact sites + the uniform fix (→ bare) are listed; the
  fallback (`pump(Duration)` for a genuine delay) is specified.
