# Test Double Convention Implementation Plan (#155)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Document a clear three-category test-double convention (mocktail mock / hand-written fake / Dio handler stub) in `CLAUDE.md` and `docs/testing-architecture.md`, with explicit "purpose-built, don't consolidate" guidance.

**Architecture:** Documentation-only. No test code changes. Two files edited with consistent wording; verified by a single full-suite confirmation run (unchanged).

**Tech Stack:** Markdown docs; Flutter project (`fvm flutter test` for the confirmation run).

---

## File structure

- Modify `CLAUDE.md` (Testing section) — Task 1.
- Modify `docs/testing-architecture.md` ("Mocks and fakes" section) — Task 2.
- Verify — Task 3.

---

## Task 1: Add the convention to `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (Testing section)

- [ ] **Step 1: Append a "Test doubles" bullet group**

In `CLAUDE.md`, find the `## Testing` section. Its last bullet is:
```markdown
- Full test structure, per-layer patterns, and guard tests: see `docs/testing-architecture.md`.
```
Insert the following bullet group IMMEDIATELY BEFORE that "Full test structure" line (so the doc-pointer stays last):

```markdown
- **Test doubles** — reach for a `mocktail` mock first; drop to a hand-fake only for genuine stateful behavior; Dio handlers are always hand-written:
  - **mocktail mock (default):** the `Mock*` classes in `test/mocks/mock_classes.dart`, for interface doubles configured with `when(...)` / `verify(...)` (repository / use-case / BLoC).
  - **hand-written fake:** a private `_Fake*` / `_Memory*` class next to the test when it needs real stateful behavior (in-memory store, throw-on-Nth-call, selective/sequenced failures, return-driven branching). These are **purpose-built per test** — same-named fakes in different files are not duplication; do not force them into shared "god" fakes.
  - **Dio handler stub:** a private `_Test*Handler` / `_StubInterceptor` extending Dio's `Interceptor` / `RequestInterceptorHandler` / `ResponseInterceptorHandler` / `ErrorInterceptorHandler`, to test interceptors at the Dio layer (can't be mocked cleanly).
```

- [ ] **Step 2: Verify placement**

Run: `sed -n '/## Testing/,/^## /p' CLAUDE.md`
Expected: the new "Test doubles" bullet group appears, and the `Full test structure ... see docs/testing-architecture.md` line is the LAST bullet in the section.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: document mock/fake/Dio-stub test-double convention in CLAUDE.md (#155)"
```

---

## Task 2: Expand the convention in `docs/testing-architecture.md`

**Files:**
- Modify: `docs/testing-architecture.md` ("Mocks and fakes" section)

- [ ] **Step 1: Replace the mock-vs-fake blockquote**

In `docs/testing-architecture.md`, find this exact blockquote at the end of the `## Mocks and fakes` section:

```markdown
> **mocktail mock vs. hand-written fake:** most tests use `mocktail` mocks from
> `mock_classes.dart`. A few use a small hand-written `_FakeXRepository` when
> stateful, return-value-driven behavior makes a mock awkward (e.g.
> `user_list_bloc_test.dart`). Both are valid; reach for a mock first.
```

Replace it entirely with:

```markdown
### Choosing a test double

Three categories — **reach for a mocktail mock first**; drop to a hand-fake only
for genuine stateful behavior; Dio handlers are always hand-written:

1. **mocktail mock (default)** — the `Mock*` classes in `mock_classes.dart`. Use
   for interface doubles where the test only configures return values
   (`when(...).thenReturn` / `thenAnswer`) and verifies calls (`verify`). This is
   the default for repository / use-case / BLoC doubles.
2. **hand-written fake** — a private `_Fake*` / `_Memory*` class next to the test,
   when the double needs real stateful or behavioral logic that mocktail makes
   awkward: in-memory stores, throw-on-Nth-call, selective/sequenced failures,
   return-driven branching (e.g. `_FakeUserRepository` in `user_list_bloc_test.dart`,
   `_MemorySecureStorage`). These are **purpose-built per test** — two same-named
   fakes in different files implement different surfaces and are *not* duplication;
   do not consolidate them into a shared "god" fake.
3. **Dio handler / interceptor stub** — a private `_Test*Handler` / `_StubInterceptor`
   extending Dio's `Interceptor` / `RequestInterceptorHandler` /
   `ResponseInterceptorHandler` / `ErrorInterceptorHandler`. Used to test
   interceptors at the Dio layer; they can't be mocked cleanly, and each records
   the signals its test asserts on.
```

- [ ] **Step 2: Verify**

Run: `sed -n '/## Mocks and fakes/,/## Architecture/p' docs/testing-architecture.md`
Expected: the old blockquote is gone; the new `### Choosing a test double` subsection with the three numbered categories is present; the rest of the section (the `mock_classes.dart` / `fake_data.dart` bullets) is unchanged.

- [ ] **Step 3: Commit**

```bash
git add docs/testing-architecture.md
git commit -m "docs: expand test-double convention into three categories (#155)"
```

---

## Task 3: Verify

- [ ] **Step 1: Docs reference real classes/paths**

Run: `grep -nE "mock_classes.dart|test_env.dart|_FakeUserRepository|_MemorySecureStorage|RequestInterceptorHandler" CLAUDE.md docs/testing-architecture.md`
Expected: the referenced paths/classes appear; spot-check that `test/mocks/mock_classes.dart`, `test/features/users/application/user_list_bloc_test.dart` (contains `_FakeUserRepository`), and the Dio handler classes exist (they do).

- [ ] **Step 2: No code touched — confirm suite still green**

Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -2`
Expected: `All tests passed!` (1565, unchanged — this change is docs-only).

- [ ] **Step 3: Analyze + format unaffected**

Run: `fvm dart analyze` → `No issues found!`
Run: `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0.

---

## Self-review notes

- **Spec coverage:** three-category convention → Tasks 1 & 2; "don't consolidate"
  note → both; docs-only / no code change → Task 3 confirms. All covered.
- **No placeholders:** exact before/after markdown for both edits.
- **Consistency:** the three categories and rule of thumb are worded consistently
  across CLAUDE.md and testing-architecture.md.
