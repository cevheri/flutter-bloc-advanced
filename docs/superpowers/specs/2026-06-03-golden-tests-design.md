# Golden Test Suite — Design (#135)

**Date:** 2026-06-03
**Issue:** #135 (test-infrastructure audit follow-up; goldens half)
**Status:** Approved (design)

## Problem

The project markets a 14+ component design system and light/dark theming but has
**zero** golden / visual-regression tests. A theme-token or component change can
silently shift the UI on many screens; only manual inspection catches it. For a
template that downstream users fork and modify, goldens are the contract: "the
components look like this; if they don't, you broke them."

## Research basis (2026 standard)

- **alchemist** is the current standard golden tool; `golden_toolkit` is
  discontinued and points to alchemist.
- alchemist runs two golden kinds: **platform goldens** (human-readable text,
  local only) and **CI goldens** (text rendered as Ahem colored squares,
  identical across platforms). This solves the macOS-local vs Linux-CI font
  diff that makes naive goldens flake.
- alchemist auto-loads declared fonts (no manual `loadAppFonts`) and
  **auto-applies the `golden` tag** (reserved in `dart_test.yaml` via #154).
- API: `goldenTest(...)` + `GoldenTestScenario`; config via `AlchemistConfig` /
  `CiGoldensConfig` / `PlatformGoldensConfig`.

Sources: pub.dev/packages/alchemist, github.com/Betterment/alchemist,
verygood.ventures alchemist tutorial.

## Goals

- A maintainable golden suite covering the design-system components, shared
  widgets, and key screens, in light + dark.
- Cross-platform-stable CI goldens (Ahem) committed and verified in CI.
- A documented workflow for generating/updating goldens.
- Phased delivery — each phase independently green and shippable.

## Non-goals (YAGNI / exclusions)

- **Non-visual files:** `web_back_button_disabler` (behavioral),
  `editor_form_mode` (enum) — no golden.
- **Animation wrappers:** `app_page_transition` (transition wrapper) and
  `app_responsive_builder` (layout helper, not a visual atom) — excluded or
  captured only at representative fixed states; not pure goldens.
- `app_loading_overlay` (continuous spinner) — captured at a single pumped frame
  if included; never a settling animation.

## Architecture

### Tooling & harness
- Add `alchemist` to `dev_dependencies`.
- `test/flutter_test_config.dart` sets a default `AlchemistConfig` (project light
  theme as the base; dark handled per-scenario/file). Fonts auto-load.
- Golden tests use `goldenTest(...)` with a `GoldenTestScenario` grid: one file
  per component/widget/screen, showing its variants/states, in light and dark.

### Bootstrap interaction
The global `setUp` runs `TestEnv.reset()` before every test. Golden tests don't
need it, but it's harmless (no widget pump). Phase 1 verifies coexistence; if any
interference appears, golden files opt out with
`setUpAll(() => TestEnv.autoReset = false);`.

### Folder layout
```
test/goldens/
  components/   <name>_golden_test.dart
  widgets/      <name>_golden_test.dart
  screens/      <name>_golden_test.dart
```
alchemist writes images under a `goldens/` subdir next to each test file. Only
the **CI (Ahem)** goldens are committed (platform-stable); platform goldens are
git-ignored or not generated in CI config.

### CI strategy
- CI runs `flutter test` (the `golden` CI variant compares against committed
  images). No `--update-goldens` in CI.
- Locally: `flutter test --update-goldens` regenerates images.
- `golden` tag (auto-applied) lets local devs run `--exclude-tags golden` for a
  fast loop, or `--tags golden` to run only goldens.
- `.gitignore`: ignore platform (non-CI) golden output if alchemist emits both.

## Scope (light + dark)

### Components (`test/goldens/components/`)
app_button, app_card, app_badge, app_avatar, app_divider, app_input,
app_empty_state, app_error_state, app_status_badge, app_skeleton, app_toast,
app_sheet, app_form. (Excludes app_page_transition, app_responsive_builder;
app_loading_overlay only as a fixed frame if included.)

### Shared widgets (`test/goldens/widgets/`)
app_data_table, app_mobile_card_list, app_responsive_list_view,
confirmation_dialog_widget, language_selection_dialog, theme_selection_dialog,
responsive_form_widget, submit_button_widget, user_form_fields.

### Screens (`test/goldens/screens/`)
login, dashboard/home, user list, user editor, account, settings,
change_password, forgot_password, register, dynamic_form — rendered with **mocked
BLoCs** (from `test/mocks/mock_classes.dart`) seeded to a deterministic loaded
state. Highest maintenance; isolated in the last phase.

## Phasing (each phase green & shippable)

- **Phase 1 — Harness + first component.** Add alchemist, config in
  `flutter_test_config.dart`, folder, `app_button_golden_test.dart` (light+dark
  variants), generate + commit CI goldens, verify `flutter test --tags golden`
  green, confirm CI comparison works, document the workflow. **De-risks
  alchemist + bootstrap + CI font behavior before mass production.**
- **Phase 2 — Remaining components** (~12 files).
- **Phase 3 — Shared widgets** (~9 files).
- **Phase 4 — Screens** (~10 files, mocked BLoCs).

Each phase is its own implementation plan; later phases proceed only after the
prior phase is green and merged.

## Documentation
- `docs/testing-architecture.md`: replace the "Goldens: none yet (#135)" gap
  bullet with the golden workflow (alchemist, `--update-goldens`, CI variant,
  folder layout, exclusions).
- `README.md`: add the golden update/run commands.

## Verification (per phase)
- `flutter test --tags golden` green; CI goldens committed.
- Full `flutter test` green; `dart analyze` clean; `dart format` clean.
- CI (ubuntu) compares against committed CI goldens without font flake.

## Acceptance
- alchemist harness in place; golden files for components + widgets + screens
  (per exclusions), light + dark; CI-stable goldens committed and CI-verified;
  workflow documented. Delivered in 4 green phases.
