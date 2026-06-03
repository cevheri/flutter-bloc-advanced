# dart_test.yaml + Test Tags — Design (#154)

**Date:** 2026-06-03
**Issue:** #154 (test-infrastructure audit follow-up)
**Status:** Approved (design)

## Problem

There is no `dart_test.yaml` and no test tagging. The suite cannot be sliced
(fast unit-only vs heavier widget vs platform-sensitive golden vs on-device
integration), per-category timeouts can't be set, and there is no declared
vocabulary for the golden/integration categories that issues #135 and #152 will
add. CI runs one undifferentiated `flutter test --timeout=30s`.

## Research basis (2026 Dart/Flutter standard)

- All tags used with `--tags`/`--exclude-tags` **must be declared** in
  `dart_test.yaml`, or `flutter test` warns "unrecognized tag". Declaring needs
  no config (`golden:` alone suffices). — dart-lang/test configuration docs.
- `dart_test.yaml` supports a default `timeout:` and per-tag
  `timeout`/`skip`/`add_tags`. `flutter test` honors the file, `--tags`,
  `--exclude-tags`, and `testWidgets(tags: ...)`.
- Idiomatic practice tags the **special** categories that must be isolated
  (golden = platform-sensitive; integration = slow/on-device) and leaves fast
  default tests untagged. The `alchemist` golden package (the planned tool for
  #135) **auto-applies the `golden` tag**, so reserving it now is forward-correct.
- File-level `@Tags(['widget'])` (a library annotation) is the idiomatic way to
  mark an entire file's tests.

Sources: dart-lang/test `configuration.md`, dart.dev/tools/testing,
pub.dev/packages/alchemist, flutter_test `testWidgets` API.

## Goals

- Declare a tag vocabulary so `--tags`/`--exclude-tags` work warning-free.
- Enable a fast unit-only loop and isolate heavy/widget tests.
- Reserve `golden` and `integration` so #135/#152 land already-isolated.
- Centralize the per-test timeout; give slow categories more.
- Document the run commands. No test behavior change; suite stays green.

## Non-goals (YAGNI)

- Do **not** create placeholder golden/integration tests — reserve the tags only.
- Do **not** tag the ~108 pure-unit/bloc files — untagged = the default fast set
  (idiomatic; tagging everything is churn for no benefit).

## Design

### 1. `dart_test.yaml` (repo root)

```yaml
# Tag vocabulary. All tags used with --tags/--exclude-tags must be declared here
# or `flutter test` warns about unrecognized tags. Declaring needs no body.
tags:
  widget:        # widget tests (testWidgets) — need a binding + pump; heavier than pure unit
  golden:        # golden / visual-regression — platform-sensitive, run in isolation (#135;
                 # alchemist auto-applies this tag). Reserved: no members yet.
  integration:   # on-device end-to-end (#152). Reserved: no members yet.
    timeout: 2x

# Per-test timeout. package:test default is 30s; mirrors the current CI flag so
# behavior is unchanged. golden/integration get more via their tag config.
timeout: 30s
```

### 2. Tag application

- Add the library annotation to the **29 widget-test files** (those using
  `testWidgets`), at the very top:
  ```dart
  @Tags(['widget'])
  library;

  import 'package:flutter_test/flutter_test.dart';
  // ...rest unchanged
  ```
  All 29 files are confirmed to have no existing `library;`/`@Tags`/`part`
  directive, so placement is uniform.
- `golden` / `integration` get no members in this change.

### 3. CI (`.github/workflows/build_and_test.yml`)

- The per-test timeout now lives in `dart_test.yaml`, so drop `--timeout=30s`
  from the `flutter test` line (behavior unchanged). Keep `--coverage
  --concurrency=4 --reporter=compact`. CI continues to run **all** tests
  (including widget); tags are for slicing, not for excluding coverage in CI.
- (`sonar_scanner.yml` runs `flutter test --coverage` — unchanged.)

### 4. Documentation

- `README.md` Test section: add tag commands —
  `flutter test --exclude-tags widget` (fast unit loop),
  `flutter test --tags widget` (widget only),
  and note `golden`/`integration` are reserved for #135/#152.
- `docs/testing-architecture.md`: update the "Tags/presets" bullet — the
  vocabulary now exists; describe the tags and that golden/integration are
  reserved.

## Verification

- `flutter test` emits **no** "unrecognized tag" warnings (all declared).
- `flutter test --tags widget` runs exactly the 29 widget files.
- `flutter test --exclude-tags widget` runs the rest with no widget files.
- Full `flutter test` green (1565), `dart analyze` clean, `dart format` clean.

## Acceptance

- `dart_test.yaml` exists with declared `widget`/`golden`/`integration` tags +
  default timeout + per-tag timeout for integration.
- The 29 widget-test files carry `@Tags(['widget'])`.
- CI timeout centralized; run commands documented; suite green.
