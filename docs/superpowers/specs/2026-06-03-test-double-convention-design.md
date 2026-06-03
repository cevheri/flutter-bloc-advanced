# Test Double Convention — Design (#155)

**Date:** 2026-06-03
**Issue:** #155 (test-infrastructure audit follow-up)
**Status:** Approved (design)

## Problem

The suite mixes `mocktail` mocks and hand-written fakes for test doubles with no
documented rule, so contributors to this community template can't tell which to
reach for. The audit issue suggested consolidating "duplicated" doubles.

## Investigation (changed the scope)

Audited all 57 hand-rolled doubles. They fall into three categories and are
**purpose-built, not duplicated**:

1. **Stateful/behavioral fakes** — `_MemorySecureStorage`, `_FlakyDeleteSecureStorage`,
   `_ReadThrowsSecureStorage`, `_SelectiveFailSecureStorage`, etc. Encode in-memory
   state or fail-on-Nth-call behavior.
2. **Dio handler/interceptor stubs** — `_TestRequestHandler`/`_TestResponseHandler`/
   `_TestErrorHandler`, `_StubInterceptor`. Extend Dio's handler classes; can't be
   mocked cleanly.
3. **Repository/use-case interface fakes** — `_FakeUserRepository`, `_FakeAccountRepository`,
   etc. Have centralized `mocktail` equivalents (`MockIUserRepository`, ...).

Verified that the apparent duplicates are **same-named but genuinely different**:
the two `_FakeUserRepository` classes implement different method surfaces
(list/delete vs retrieve/create); the two `_FakeAccountRepository` classes track
different fields (`registerResult` vs `account`+`failure`); even the Dio
`_Test*Handler` classes capture different signals per file (logging uses
`nextOptions`/`nextResponse`; cache uses `resolvedResponse`/`rejectedError`;
resilience uses an `_InterceptorResult` value object). Consolidating any of them
would create kitchen-sink/god doubles that **reduce** per-test clarity.

**Conclusion:** the real gap is the missing convention, not duplication. This is
a documentation-only change. No test code is touched.

## Goals

- Document a clear, three-category rule for choosing a test double.
- State explicitly that purpose-built per-test fakes are correct and must not be
  force-consolidated.
- No code/test changes; no behavior change.

## Non-goals (YAGNI)

- No consolidation of any existing double (verified to trade clarity for churn).
- No conversion of hand-fakes to mocktail or vice versa.

## Design

Documentation in two places, consistent wording.

### Convention — three categories

1. **mocktail mock (default).** Use the `Mock*` classes in
   `test/mocks/mock_classes.dart` for interface doubles where the test only
   configures return values (`when(...).thenReturn/thenAnswer`) and verifies
   calls (`verify`). This is the default for repository / use-case / BLoC doubles.
2. **Hand-written fake.** Use a private `_Fake*` / `_Memory*` class next to the
   test when the double needs genuine stateful or behavioral logic that mocktail
   makes awkward: in-memory stores, throw-on-Nth-call, selective/sequenced
   failures, return-driven branching. These are **expected to be purpose-built
   per test** — do not force them into shared "god" fakes.
3. **Dio handler/interceptor stub.** Use a private `_Test*Handler` /
   `_StubInterceptor` (extending Dio's `Interceptor` / `RequestInterceptorHandler`
   / `ResponseInterceptorHandler` / `ErrorInterceptorHandler`) to test
   interceptors at the Dio layer. These can't be mocked cleanly; each records the
   signals its test asserts on.

**Rule of thumb:** reach for a mocktail mock first; drop to a hand-fake only when
stateful behavior is needed; Dio handlers are always hand-written.

**Note:** same-named fakes in different files (e.g. `_FakeUserRepository` in two
bloc tests) are intentionally purpose-built, not duplication — do not consolidate.

### Placement

- `CLAUDE.md` → Testing section: a concise "Test doubles" bullet group with the
  rule of thumb + three categories.
- `docs/testing-architecture.md` → expand the existing "Mocks and fakes"
  section's mock-vs-fake note into the three categories + the no-consolidate note.

## Verification

- `dart analyze` / `dart format` unaffected (markdown only).
- Full suite unchanged (no test edits) — a single confirmation run.
- The two docs read consistently and reference real classes/paths.

## Acceptance

- The three-category convention + rule of thumb is documented in CLAUDE.md and
  testing-architecture.md.
- The "purpose-built, don't consolidate" guidance is explicit.
- No test code changed.
