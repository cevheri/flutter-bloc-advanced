# Golden Tests — Phase 3 (Shared Widgets) Implementation Plan (#135)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add golden tests (light + dark) for the shared reusable widgets in `lib/shared/widgets/`, using the harness/pattern proven in Phases 1–2.

**Architecture:** One `*_golden_test.dart` per widget under `test/goldens/widgets/`, following the established pattern: `setUpAll(() => TestEnv.autoReset = false)`, a light `goldenTest` + a dark `goldenTest` (wrap child in `Theme(data: AppTheme.dark())`), `pumpBeforeTest: pumpOnce` for any widget showing a loading spinner, no `@Tags` (alchemist auto-tags `golden`). Only CI/Ahem goldens generate/commit under `test/goldens/widgets/goldens/ci/`.

**Tech Stack:** Flutter 3.44.0, `alchemist` 0.14.0, FVM, `flutter_form_builder` (for field widgets). Generate with `fvm flutter test <file> --update-goldens`.

---

## Established pattern (from Phases 1–2 — do not re-derive)

- File starts: `setUpAll(() => TestEnv.autoReset = false);` (import `../../support/test_env.dart`).
- `GoldenTestGroup grid()` helper → `goldenTest('X — light', fileName: 'x_light', builder: grid)` + dark variant wrapping in `Theme(data: AppTheme.dark(), child: grid())`.
- Bound unconstrained widgets in `SizedBox`/`Center`.
- `pumpBeforeTest: pumpOnce` for loading/animated states.
- Reference: `test/goldens/components/app_card_golden_test.dart`.

## Widget survey (read each constructor before writing)

| File | Class | Notes |
| --- | --- | --- |
| `confirmation_dialog_widget.dart` | `ConfirmationDialog` (StatelessWidget) + `DialogType {unsavedChanges, delete, logout}` | render the widget directly (not `.show()`); one scenario per `DialogType` |
| `language_selection_dialog.dart` | `LanguageSelectionDialog` (const StatelessWidget) | render directly; single scenario |
| `theme_selection_dialog.dart` | `ThemeSelectionDialog` (const StatelessWidget) | render directly; single scenario |
| `app_data_table.dart` | `AppDataTable` + `AppTableColumn` | needs `columns` + `rows` data — build 3 columns + 3 sample rows |
| `app_mobile_card_list.dart` | `AppMobileCardList` | needs `items` + `itemBuilder` (+ maybe `isLoading`); sample 3 items. If a loading scenario is included → `pumpBeforeTest: pumpOnce` |
| `app_responsive_list_view.dart` | `AppResponsiveListView` | responsive; render at a fixed width; supply required builders/data per its constructor |
| `responsive_form_widget.dart` | `ResponsiveFormBuilder` | wraps form content; supply a simple child column of fields |
| `submit_button_widget.dart` | `ResponsiveSubmitButton` (+ `ButtonContent`) | scenarios: idle + loading (loading → `pumpBeforeTest: pumpOnce`) |
| `user_form_fields.dart` | `UserFormFields` (static field builders) | compose the fields inside a `FormBuilder` (from `flutter_form_builder`); render the resulting column |

If a constructor needs callbacks, pass no-op closures (`() {}` / `(_) {}`). If a
widget needs `MediaQuery`/width, alchemist's host provides a default surface; set
a `SizedBox(width: ...)` for responsive widgets to pin the layout.

---

## Task 1: Dialogs

**Files:**
- `test/goldens/widgets/confirmation_dialog_widget_golden_test.dart`
- `test/goldens/widgets/language_selection_dialog_golden_test.dart`
- `test/goldens/widgets/theme_selection_dialog_golden_test.dart`

- [ ] **Step 1:** Read each dialog's constructor/build. Render the WIDGET directly (do not call `.show()`).
  - `ConfirmationDialog`: read required params (likely `type` + maybe `title`/`content`/callbacks); one `GoldenTestScenario` per `DialogType` {unsavedChanges, delete, logout}.
  - `LanguageSelectionDialog` / `ThemeSelectionDialog`: const, no params — a single scenario each. Wrap in `Center` if they render as a `Dialog`/`AlertDialog`.
- [ ] **Step 2: Generate**

Run: `fvm flutter test test/goldens/widgets/confirmation_dialog_widget_golden_test.dart test/goldens/widgets/language_selection_dialog_golden_test.dart test/goldens/widgets/theme_selection_dialog_golden_test.dart --update-goldens 2>&1 | tail -4` → `All tests passed!` + PNGs under `test/goldens/widgets/goldens/ci/`.
- [ ] **Step 3: Verify (no --update) + analyze/format** → green/clean.
- [ ] **Step 4: Commit**

```bash
git add test/goldens/ && git commit -m "test: golden tests for dialogs (confirmation/language/theme) (#135 phase 3)"
```

---

## Task 2: Lists & table

**Files:**
- `test/goldens/widgets/app_data_table_golden_test.dart`
- `test/goldens/widgets/app_mobile_card_list_golden_test.dart`
- `test/goldens/widgets/app_responsive_list_view_golden_test.dart`

- [ ] **Step 1:** Read each constructor; supply sample data.
  - `AppDataTable`: build ~3 `AppTableColumn`s (e.g. Name/Email/Role) + 3 sample rows per its row API. Bound width (e.g. `SizedBox(width: 600)`).
  - `AppMobileCardList`: 3 sample items + an `itemBuilder` returning a simple card/text. If it has an `isLoading` flag, add a loading scenario and put `pumpBeforeTest: pumpOnce` on the goldenTest calls.
  - `AppResponsiveListView`: supply its required builders/data; render at `SizedBox(width: 800)` (desktop) — one representative scenario.
- [ ] **Step 2: Generate** (same command shape as Task 1, these 3 files) → pass + PNGs.
- [ ] **Step 3: Verify + analyze/format** → green/clean.
- [ ] **Step 4: Commit**

```bash
git add test/goldens/ && git commit -m "test: golden tests for data table / mobile card list / responsive list (#135 phase 3)"
```

---

## Task 3: Forms & buttons

**Files:**
- `test/goldens/widgets/responsive_form_widget_golden_test.dart`
- `test/goldens/widgets/submit_button_widget_golden_test.dart`
- `test/goldens/widgets/user_form_fields_golden_test.dart`

- [ ] **Step 1:** Write each file.
  - `ResponsiveFormBuilder`: render with a simple child (a `Column` of 2 `TextField`s or `AppInput`s) per its constructor.
  - `ResponsiveSubmitButton`: two scenarios — idle and loading. Put `pumpBeforeTest: pumpOnce` on the goldenTest calls (loading shows a spinner).
  - `UserFormFields`: it exposes static builders returning `flutter_form_builder` fields. Wrap them in a `FormBuilder(key: ..., child: Column(children: [UserFormFields.xxx(...), ...]))`. Read `user_form_fields.dart` for the exact static method names/params; render a representative set (login/firstName/lastName/email/activated). Bound width.
- [ ] **Step 2: Generate** (these 3 files) → pass + PNGs. If submit button times out, ensure `pumpBeforeTest: pumpOnce`.
- [ ] **Step 3: Verify + analyze/format** → green/clean.
- [ ] **Step 4: Commit**

```bash
git add test/goldens/ && git commit -m "test: golden tests for responsive form / submit button / user form fields (#135 phase 3)"
```

---

## Task 4: Full verification

- [ ] **Step 1: All golden tests**

Run: `fvm flutter test --tags golden -r compact 2>&1 | grep -oE "\+[0-9]+: All tests passed!|Some tests failed" | tail -1`
Expected: `All tests passed!` — now components (Phases 1–2) + 9 widget files.

- [ ] **Step 2: Full suite + analyze + format**

Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | grep -oE "\+[0-9]+: All tests passed!|Some tests failed" | tail -1` → `All tests passed!`.
Run: `fvm dart analyze` → `No issues found!`.
Run: `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0 (else `git add -A`).

- [ ] **Step 3: CI-only goldens**

Run: `find test/goldens/widgets -type d -name linux -o -type d -name macos | head` → none.
Run: `ls test/goldens/widgets/goldens/ci/*.png | wc -l` → 2 per widget file (light+dark) for the 9 widgets (≈18, allowing for extra loading-state files).

- [ ] **Step 4: Commit any formatting**

```bash
git add -A && git commit -m "test: golden phase 3 finalize (#135)" || echo "nothing to commit"
```

---

## Self-review notes

- **Spec coverage:** all 9 shared widgets from the spec's widgets list; the
  dialogs are rendered as widgets directly (unlike the deferred imperative
  toast/sheet which have no widget class).
- **Pattern reuse:** every file follows the Phase-1/2 pattern; `pumpOnce` flagged
  for loading states (mobile card list, submit button).
- **No placeholders:** the widget survey table + per-task guidance is concrete;
  implementers read each constructor for exact params (mechanical, API-driven).
- **Consistency:** `goldenTest`/`GoldenTestGroup`/`GoldenTestScenario`,
  `AppTheme.dark()`, `pumpBeforeTest: pumpOnce`, `app_<x>_light/dark` naming,
  CI-only goldens.
