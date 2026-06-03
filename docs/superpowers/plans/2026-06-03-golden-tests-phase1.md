# Golden Tests — Phase 1 (Harness) Implementation Plan (#135)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the alchemist golden-test harness and prove the full pipeline end-to-end with one component (`AppButton`, light + dark), so later phases can mass-produce golden files with confidence.

**Architecture:** Add `alchemist`; set a default `AlchemistConfig` (project light theme) in `test/flutter_test_config.dart`; add `test/goldens/components/app_button_golden_test.dart` using `goldenTest` + `GoldenTestScenario`; generate the CI (Ahem) goldens, commit them, and verify `flutter test --tags golden` is green and CI-stable. This is a **de-risking spike** — confirm alchemist's API for the resolved version, its interaction with the existing global `setUp` bootstrap, and CI font behavior.

**Tech Stack:** Flutter 3.44.0, `flutter_test`, `alchemist` (added here), FVM. Goldens generated with `fvm flutter test --update-goldens`.

---

## Key facts

- alchemist auto-loads declared fonts and **auto-applies the `golden` tag**
  (already declared in `dart_test.yaml` from #154).
- alchemist generates **CI goldens** (text → Ahem squares, platform-stable) and
  **platform goldens** (human-readable, local). Commit the **CI** goldens; CI
  compares against them with a plain `flutter test`.
- `AppButton` (`lib/shared/design_system/components/app_button.dart`): `variant`
  ∈ {filled, outlined, text, ghost, destructive, icon}, `size` ∈ {sm, md, lg},
  plus `label`, `icon`, `isLoading`. The `icon` variant needs an `icon`.
- `AppTheme.light()` / `AppTheme.dark()` (`lib/shared/design_system/theme/app_theme.dart`)
  return `ThemeData`.
- The global `setUp` in `flutter_test_config.dart` runs `TestEnv.reset()` before
  every test — harmless for goldens (no widget pump). Verify in Step "run".

## File structure

- Modify `pubspec.yaml` — add `alchemist` dev dep (Task 1).
- Modify `test/flutter_test_config.dart` — default `AlchemistConfig` (Task 2).
- Create `test/goldens/components/app_button_golden_test.dart` + generated
  goldens (Task 3).
- Modify `.gitignore`, `README.md`, `docs/testing-architecture.md` (Task 4).

---

## Task 1: Add alchemist

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dev dependency**

Run: `fvm flutter pub add dev:alchemist`
Expected: resolves a version compatible with Flutter 3.44 / Dart ^3.12 and updates `pubspec.yaml` + `pubspec.lock`. If resolution fails, run `fvm flutter pub add dev:alchemist:any` and pin the resolved version; report the version chosen.

- [ ] **Step 2: Verify it resolves + imports**

Run: `fvm flutter pub get` → success.
Run: `fvm dart analyze` → `No issues found!` (no usage yet, just dependency present).

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "test: add alchemist dev dependency for golden tests (#135)"
```

---

## Task 2: Default AlchemistConfig in the bootstrap

**Files:**
- Modify: `test/flutter_test_config.dart`

- [ ] **Step 1: Wrap testMain in AlchemistConfig**

Update `test/flutter_test_config.dart` so the suite runs under a default
`AlchemistConfig` carrying the project's light theme. Add the import and wrap the
`testMain` call. Resulting file:

```dart
import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mock_classes.dart';
import 'support/test_env.dart';

/// Global test bootstrap, auto-discovered by `flutter test` for everything
/// under `test/`. Runs one-time config per isolate and an automatic per-test
/// environment reset. Files that manage the secure-storage MethodChannel
/// themselves opt out via `setUpAll(() => TestEnv.autoReset = false);`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // One-time per isolate.
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  EquatableConfig.stringify = true;
  registerAllFallbackValues();

  // Per-test, unless a file opts out.
  setUp(() async {
    if (TestEnv.autoReset) await TestEnv.reset();
  });
  tearDown(() async {
    if (TestEnv.autoReset) await TestEnv.reset();
  });

  // Golden tests (alchemist) render under the project light theme by default;
  // dark-theme scenarios wrap their child in AppTheme.dark() explicitly.
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(theme: AppTheme.light()),
    run: testMain,
  );
}
```

- [ ] **Step 2: Verify analyze + a non-golden test still passes**

Run: `fvm dart analyze test/flutter_test_config.dart` → `No issues found!`.
Run: `fvm flutter test test/core/result/result_test.dart -r compact 2>&1 | tail -2` → `All tests passed!` (wrapping in AlchemistConfig must not break ordinary tests).

If `AlchemistConfig`'s API differs in the resolved version (e.g. parameter name
for the theme, or `runWithConfig` signature), consult
`fvm dart doc`/the alchemist pub docs and adapt minimally — the intent is "set a
default light-theme config around the whole suite." Report any API adaptation.

- [ ] **Step 3: Commit**

```bash
git add test/flutter_test_config.dart
git commit -m "test: set default AlchemistConfig (light theme) in bootstrap (#135)"
```

---

## Task 3: First golden — AppButton (light + dark)

**Files:**
- Create: `test/goldens/components/app_button_golden_test.dart`
- Create (generated): `test/goldens/components/goldens/*.png`

- [ ] **Step 1: Write the golden test**

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A representative grid of button variants + a loading state. The `icon`
  // variant needs an icon; all others use a text label.
  GoldenTestGroup grid() => GoldenTestGroup(
        columns: 3,
        children: [
          for (final v in AppButtonVariant.values)
            GoldenTestScenario(
              name: v.name,
              child: v == AppButtonVariant.icon
                  ? AppButton(variant: v, icon: Icons.add, onPressed: () {})
                  : AppButton(label: 'Button', variant: v, onPressed: () {}),
            ),
          GoldenTestScenario(
            name: 'loading',
            child: const AppButton(label: 'Button', isLoading: true),
          ),
        ],
      );

  goldenTest(
    'AppButton — light',
    fileName: 'app_button_light',
    builder: grid,
  );

  goldenTest(
    'AppButton — dark',
    fileName: 'app_button_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
```

- [ ] **Step 2: Generate the goldens**

Run: `fvm flutter test test/goldens/components/app_button_golden_test.dart --update-goldens 2>&1 | tail -3`
Expected: `All tests passed!` and PNGs created under
`test/goldens/components/goldens/`.

If the alchemist API differs (e.g. `GoldenTestGroup` takes `columns` differently,
or `builder` returns a `Widget` directly), adapt to the resolved version's API
(consult alchemist docs) — keep the intent: a light grid + a dark grid of the
button variants. Report any adaptation.

- [ ] **Step 3: Inspect the generated images**

Run: `ls -la test/goldens/components/goldens/`
Expected: PNG file(s) for `app_button_light` and `app_button_dark`. Open them (or
note their size > 0) to confirm they rendered (Ahem squares for text in CI mode
is expected and correct).

- [ ] **Step 4: Verify the test passes against committed goldens (no --update)**

Run: `fvm flutter test test/goldens/components/app_button_golden_test.dart -r compact 2>&1 | tail -2`
Expected: `All tests passed!` (now comparing, not regenerating).

- [ ] **Step 5: Verify the golden tag works**

Run: `fvm flutter test --tags golden -r compact 2>&1 | tail -2`
Expected: `All tests passed!` and only the golden test(s) run (alchemist
auto-tags `golden`).

- [ ] **Step 6: Commit (test + generated goldens)**

```bash
git add test/goldens/
git commit -m "test: add AppButton golden (light + dark) — alchemist harness proven (#135)"
```

---

## Task 4: gitignore platform goldens + docs

**Files:**
- Modify: `.gitignore`
- Modify: `README.md`
- Modify: `docs/testing-architecture.md`

- [ ] **Step 1: Ignore platform (non-CI) goldens if alchemist emits them**

Check what alchemist generated: if it created a separate platform-goldens
directory (human-readable, e.g. `**/goldens/ci/` vs platform), commit only the CI
goldens and ignore the platform ones. Inspect:
Run: `find test/goldens -type d`
- If there is a platform-vs-ci split (e.g. a `failures/` dir or `platform` images),
  add to `.gitignore`:
  ```
  # Alchemist platform goldens + failure diffs (CI goldens are committed)
  test/**/failures/
  ```
  (Always ignore `failures/` — alchemist writes diff images there on mismatch.)
- If alchemist committed a single CI golden set, just ensure `failures/` is ignored.

- [ ] **Step 2: README golden commands**

In `README.md`, after the test tag commands added in #154, add:

```shell
# Golden / visual-regression tests (alchemist)
fvm flutter test --tags golden                 # run goldens (CI variant)
fvm flutter test --tags golden --update-goldens # regenerate after intentional UI changes
```

And a sentence:
```markdown
Golden images live under `test/goldens/`. CI compares against the committed
(Ahem-rendered) goldens; regenerate locally with `--update-goldens` after an
intentional visual change.
```

- [ ] **Step 3: Update `docs/testing-architecture.md` Goldens bullet**

Replace the existing bullet:
```markdown
- **Goldens:** there are no golden/visual-regression tests yet (issue #135). The
  bootstrap is where font loading will be wired when they land.
```
with:
```markdown
- **Goldens:** golden / visual-regression tests use `alchemist`
  (`test/goldens/`). The bootstrap sets a default `AlchemistConfig` (light
  theme); dark scenarios wrap their child in `AppTheme.dark()`. CI compares
  against committed CI (Ahem-rendered) goldens; regenerate locally with
  `flutter test --tags golden --update-goldens`. Phase 1 covers the harness +
  `AppButton`; remaining components, widgets, and screens land in later phases.
```

- [ ] **Step 4: Commit**

```bash
git add .gitignore README.md docs/testing-architecture.md
git commit -m "docs: document golden workflow; ignore alchemist failure diffs (#135)"
```

---

## Task 5: Full verification

- [ ] **Step 1: Full suite (goldens included)**

Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -2`
Expected: `All tests passed!` (1565 + the new golden test count).

- [ ] **Step 2: Analyze + format**

Run: `fvm dart analyze` → `No issues found!`.
Run: `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0 (if it reformats, `git add -A` and amend/commit).

- [ ] **Step 3: Confirm CI-stability reasoning**

Confirm the committed goldens are the CI (Ahem) variant (text rendered as
squares). This is what makes them stable on CI ubuntu vs local. Note in the PR
that goldens were generated locally and CI verifies them.

- [ ] **Step 4: Commit any formatting**

```bash
git add -A && git commit -m "test: golden phase 1 finalize (#135)" || echo "nothing to commit"
```

---

## Self-review notes

- **Spec coverage (Phase 1 slice):** harness (Tasks 1–2), first component
  light+dark (Task 3), CI/gitignore + docs (Task 4), verification (Task 5).
- **De-risking:** Tasks 2 & 3 explicitly allow adapting to the resolved
  alchemist API and report adaptations — appropriate for a spike.
- **No placeholders:** concrete pubspec command, full bootstrap file, full golden
  test, exact doc edits. The only intentional flex is "adapt to resolved
  alchemist API version," which is the point of the de-risking phase.
- **Consistency:** `AppTheme.light()/.dark()`, `AlchemistConfig`, `goldenTest`,
  `GoldenTestScenario`/`GoldenTestGroup`, the `golden` tag used consistently.
```
