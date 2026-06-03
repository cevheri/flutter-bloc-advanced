# Golden Tests — Phase 2 (Components) Implementation Plan (#135)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add golden tests (light + dark) for the remaining renderable design-system components, using the harness proven in Phase 1.

**Architecture:** One `*_golden_test.dart` per component under `test/goldens/components/`, each following the Phase-1 pattern: `setUpAll(() => TestEnv.autoReset = false)`, a `goldenTest` light grid + a dark grid (wrap in `Theme(data: AppTheme.dark())`), `pumpBeforeTest: pumpOnce` for animated widgets. Only CI (Ahem) goldens are generated/committed (platform goldens are disabled globally).

**Tech Stack:** Flutter 3.44.0, `alchemist` 0.14.0, FVM. Generate with `fvm flutter test <file> --update-goldens`.

---

## Established pattern (from Phase 1 — do not re-derive)

- Golden files MUST start `main()` with `setUpAll(() => TestEnv.autoReset = false);` (import `../../support/test_env.dart`) — the global `TestEnv.reset()` interferes with the golden lifecycle.
- Animated widgets (shimmer/spinner) MUST pass `pumpBeforeTest: pumpOnce` to `goldenTest` or they time out on `onlyPumpAndSettle`.
- The bootstrap (`test/flutter_test_config.dart`) already sets `AlchemistConfig(theme: AppTheme.light(), platformGoldensConfig: PlatformGoldensConfig(enabled: false))`. Light is the default; dark scenarios wrap their child in `Theme(data: AppTheme.dark(), child: ...)`.
- alchemist auto-tags `golden`; CI goldens land under `test/goldens/components/goldens/ci/`.

## Uniform golden-file template

Each component file follows this shape (example: `app_card`):

```dart
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_card.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
        columns: 3,
        children: [
          for (final v in AppCardVariant.values)
            GoldenTestScenario(
              name: v.name,
              child: SizedBox(
                width: 200,
                child: AppCard(variant: v, child: const Padding(padding: EdgeInsets.all(16), child: Text('Card body'))),
              ),
            ),
        ],
      );

  goldenTest('AppCard — light', fileName: 'app_card_light', builder: grid);
  goldenTest('AppCard — dark', fileName: 'app_card_dark', builder: () => Theme(data: AppTheme.dark(), child: grid()));
}
```

(Note the `@Tags(['golden'])` library annotation is optional — alchemist auto-tags — but harmless and explicit; include it for consistency with the widget-tag convention. If it causes a duplicate-tag issue, drop it and rely on alchemist's auto-tag.)

Wrap any scenario child in a bounded `SizedBox`/`Center` where the component would otherwise be unconstrained.

## Components & scenarios

Read each component's constructor before writing its grid; the scenarios below are the intended coverage (derived from each public API).

| File | Component | Scenarios (one per `GoldenTestScenario`) | Animated? |
| --- | --- | --- | --- |
| `app_card_golden_test.dart` | `AppCard` | each `AppCardVariant` {elevated, outlined, filled} with a text body | no |
| `app_badge_golden_test.dart` | `AppBadge(label, variant, icon?)` | each `AppBadgeVariant` {filled, secondary, destructive, outline, success, warning}; one with an `icon` | no |
| `app_avatar_golden_test.dart` | `AppAvatar` | each `AppAvatarStatus` {online, offline, away, none}; initials + (if supported) image fallback | no |
| `app_divider_golden_test.dart` | `AppDivider({label?})` | plain divider; divider with `label: 'OR'` | no |
| `app_input_golden_test.dart` | `AppInput` | `AppInputVariant` {standard, search}; one empty, one with text, one with `errorText` if the API supports it | no |
| `app_empty_state_golden_test.dart` | `AppEmptyState` | a typical empty state (icon + title + message + optional action) | no |
| `app_error_state_golden_test.dart` | `AppErrorState` | a typical error state (icon + message + retry action) | no |
| `app_status_badge_golden_test.dart` | `AppStatusBadge(label, color)` | 2-3 colors (e.g. success/green, warning/amber, error/red) | no |
| `app_skeleton_golden_test.dart` | `AppSkeleton(shape)` | each `AppSkeletonShape` {text, circle, rectangle, card, listTile} — **use `pumpBeforeTest: pumpOnce`** (shimmer animates) | YES |
| `app_form_golden_test.dart` | `AppFormCard`/`AppFormField`/`AppFormSection`/`AppFormActions` | one composed form: a `AppFormCard` with a `AppFormSection` containing two `AppFormField`s and an `AppFormActions` footer | no |

**Excluded from Phase 2 (imperative show-helpers, not widgets):** `AppToast`
(`AppToast.show(...)`) and `AppSheet` (`AppSheet.show(...)`) — they display an
overlay/modal imperatively rather than returning a widget. Golden-ing them needs
a host + pump-overlay; defer to the screens phase (Phase 4) or a dedicated
follow-up. Also excluded (per spec): `app_page_transition`, `app_responsive_builder`,
`app_loading_overlay` (handled, if at all, as a fixed-frame in a later pass).

---

## Task 1: Card / Badge / Avatar / Divider

**Files (create each + its generated `goldens/ci/*.png`):**
- `test/goldens/components/app_card_golden_test.dart`
- `test/goldens/components/app_badge_golden_test.dart`
- `test/goldens/components/app_avatar_golden_test.dart`
- `test/goldens/components/app_divider_golden_test.dart`

- [ ] **Step 1:** For each component, read its constructor in `lib/shared/design_system/components/<name>.dart`, then write the golden file using the template + the scenarios from the table. Bound unconstrained widgets in a `SizedBox`/`Center`.
- [ ] **Step 2: Generate goldens**

Run: `fvm flutter test test/goldens/components/app_card_golden_test.dart test/goldens/components/app_badge_golden_test.dart test/goldens/components/app_avatar_golden_test.dart test/goldens/components/app_divider_golden_test.dart --update-goldens 2>&1 | tail -4`
Expected: `All tests passed!`, PNGs under `.../goldens/ci/`.

- [ ] **Step 3: Verify comparison + analyze**

Run: `fvm flutter test test/goldens/components/app_card_golden_test.dart test/goldens/components/app_badge_golden_test.dart test/goldens/components/app_avatar_golden_test.dart test/goldens/components/app_divider_golden_test.dart -r compact 2>&1 | tail -2` → `All tests passed!`
Run: `fvm dart analyze` → `No issues found!`; `fvm dart format <the 4 files> --line-length=120`.

- [ ] **Step 4: Commit**

```bash
git add test/goldens/ && git commit -m "test: golden tests for card/badge/avatar/divider (#135 phase 2)"
```

---

## Task 2: Input / EmptyState / ErrorState / StatusBadge

**Files:**
- `test/goldens/components/app_input_golden_test.dart`
- `test/goldens/components/app_empty_state_golden_test.dart`
- `test/goldens/components/app_error_state_golden_test.dart`
- `test/goldens/components/app_status_badge_golden_test.dart`

- [ ] **Step 1:** Read each component's constructor and write the golden file (template + table scenarios). For `AppInput`, check whether it exposes `errorText`/`hintText`/`label` and include an error scenario if available.
- [ ] **Step 2: Generate**

Run: `fvm flutter test test/goldens/components/app_input_golden_test.dart test/goldens/components/app_empty_state_golden_test.dart test/goldens/components/app_error_state_golden_test.dart test/goldens/components/app_status_badge_golden_test.dart --update-goldens 2>&1 | tail -4` → pass + PNGs.

- [ ] **Step 3: Verify + analyze/format** (same commands as Task 1, for these 4 files) → green/clean.

- [ ] **Step 4: Commit**

```bash
git add test/goldens/ && git commit -m "test: golden tests for input/empty-state/error-state/status-badge (#135 phase 2)"
```

---

## Task 3: Skeleton (animated) / Form

**Files:**
- `test/goldens/components/app_skeleton_golden_test.dart`
- `test/goldens/components/app_form_golden_test.dart`

- [ ] **Step 1:** Write both golden files.
  - `app_skeleton`: grid of each `AppSkeletonShape`; pass `pumpBeforeTest: pumpOnce` to BOTH `goldenTest` calls (shimmer animates and would otherwise time out).
  - `app_form`: compose `AppFormCard` → `AppFormSection` (title) → two `AppFormField`s (label + a `TextField`/`AppInput` child) → `AppFormActions` footer; read the four classes' constructors in `app_form.dart` for required params.
- [ ] **Step 2: Generate**

Run: `fvm flutter test test/goldens/components/app_skeleton_golden_test.dart test/goldens/components/app_form_golden_test.dart --update-goldens 2>&1 | tail -4` → pass + PNGs.
If `app_skeleton` times out, confirm `pumpBeforeTest: pumpOnce` is on both goldenTest calls.

- [ ] **Step 3: Verify + analyze/format** → green/clean.

- [ ] **Step 4: Commit**

```bash
git add test/goldens/ && git commit -m "test: golden tests for skeleton (pumpOnce) and form (#135 phase 2)"
```

---

## Task 4: Full verification

- [ ] **Step 1: All golden tests**

Run: `fvm flutter test --tags golden -r compact 2>&1 | tail -2`
Expected: `All tests passed!` — now ~11 component golden files (Phase 1's app_button + Phase 2's 10).

- [ ] **Step 2: Full suite + analyze + format**

Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -2` → `All tests passed!`.
Run: `fvm dart analyze` → `No issues found!`.
Run: `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0 (else `git add -A`).

- [ ] **Step 3: Confirm only CI goldens committed**

Run: `find test/goldens -type d -name linux -o -type d -name macos | head` → no platform dirs.
Run: `git status --short` → only `ci/` PNGs + test files staged/committed.

- [ ] **Step 4: Commit any formatting**

```bash
git add -A && git commit -m "test: golden phase 2 finalize (#135)" || echo "nothing to commit"
```

---

## Self-review notes

- **Spec coverage:** all renderable components from the spec's component list
  (minus app_button done in Phase 1, minus the imperative toast/sheet + excluded
  animation/layout helpers, which are explicitly deferred with reasons).
- **Pattern reuse:** every file follows the Phase-1 pattern (autoReset opt-out,
  light+dark, pumpOnce for animated). No re-derivation.
- **No placeholders:** the template is real code; per-component scenarios are an
  explicit table; the implementer reads each constructor to fill specifics
  (mechanical, API-driven).
- **Consistency:** `GoldenTestGroup`/`GoldenTestScenario`/`goldenTest`,
  `AppTheme.dark()`, `pumpBeforeTest: pumpOnce`, file naming `app_<x>_light/dark`.
