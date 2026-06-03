# dart_test.yaml + Test Tags Implementation Plan (#154)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `dart_test.yaml` declaring a `widget`/`golden`/`integration` tag vocabulary (+ timeouts), tag the 29 widget-test files with `@Tags(['widget'])`, centralize the CI timeout, and document the run commands.

**Architecture:** A single root `dart_test.yaml` declares tags so `flutter test --tags`/`--exclude-tags` work warning-free; the 29 `testWidgets` files get a file-level `@Tags(['widget'])` library annotation. `golden`/`integration` are declared but unused (reserved for #135/#152). Untagged files remain the default fast set.

**Tech Stack:** Flutter 3.44.0, `flutter_test`, `dart_test.yaml` (package:test config), FVM. Run with `fvm flutter test`.

---

## Key facts

- All tags used with `--tags`/`--exclude-tags` must be declared in `dart_test.yaml` or `flutter test` warns. Declaring needs no body.
- `@Tags(['widget'])` is a **library annotation** — must be at the very top of the file, before imports, followed by `library;`.
- All 29 target files confirmed to have no existing `library;`/`@Tags`/`part` directive, so placement is uniform.
- `flutter test` honors `dart_test.yaml` `tags:`/`timeout:`, `--tags`, `--exclude-tags`.

## File structure

- Create `dart_test.yaml` (repo root) — Task 1.
- Modify 29 `*_test.dart` files (add `@Tags(['widget']) library;`) — Task 2.
- Modify `.github/workflows/build_and_test.yml` — Task 3.
- Modify `README.md` + `docs/testing-architecture.md` — Task 4.

---

## Task 1: Create `dart_test.yaml`

**Files:**
- Create: `dart_test.yaml` (repo root)

- [ ] **Step 1: Write `dart_test.yaml`**

```yaml
# Test configuration (package:test / flutter test).
#
# All tags used with `flutter test --tags` / `--exclude-tags` must be declared
# here, otherwise the runner warns about unrecognized tags. Declaring a tag
# needs no body.
tags:
  # Widget tests (use `testWidgets`) — need a binding + pump; heavier than pure
  # unit tests. Applied via a file-level `@Tags(['widget'])` annotation.
  widget:
  # Golden / visual-regression tests — platform-sensitive, run in isolation.
  # Reserved for #135 (the alchemist golden package auto-applies this tag).
  golden:
  # On-device end-to-end tests. Reserved for #152.
  integration:
    timeout: 2x

# Per-test timeout. package:test's default is 30s; this mirrors the previous CI
# `--timeout=30s` flag so behavior is unchanged. Slow categories override via tag.
timeout: 30s
```

- [ ] **Step 2: Verify the runner accepts it (no unrecognized-tag warnings)**

Run: `fvm flutter test test/core/result/result_test.dart -r compact 2>&1 | tail -5`
Expected: `All tests passed!` with NO line containing "Unknown tag" / "unrecognized". (Running one tiny file is enough to prove the config parses.)

- [ ] **Step 3: Commit**

```bash
git add dart_test.yaml
git commit -m "test: add dart_test.yaml declaring widget/golden/integration tags (#154)"
```

---

## Task 2: Tag the 29 widget-test files

**Files (add `@Tags(['widget'])` + `library;` at the very top of each):**
- test/app/connectivity/connectivity_banner_test.dart
- test/app/dev_console/tabs/environment_tab_test.dart
- test/app/dev_console/tabs/network_tab_test.dart
- test/app/localization/localization_test.dart
- test/app/router/app_router_factory_test.dart
- test/app/router/app_router_strategy_test.dart
- test/app/router/router_test.dart
- test/app/shell/top_bar/breadcrumb_widget_test.dart
- test/features/account/presentation/pages/account_screen_test.dart
- test/features/auth/presentation/pages/change_password_screen_test.dart
- test/features/auth/presentation/pages/forgot_password_screen_test.dart
- test/features/auth/presentation/pages/register_screen_go_router_test.dart
- test/features/auth/presentation/widgets/community_section_widget_test.dart
- test/features/auth/presentation/widgets/login_otp_email_widget_test.dart
- test/features/auth/presentation/widgets/login_otp_verify_widget_test.dart
- test/features/dashboard/presentation/pages/dashboard_page_test.dart
- test/features/dashboard/presentation/pages/home_screen_test.dart
- test/features/settings/presentation/pages/settings_screen_test.dart
- test/features/users/presentation/pages/list_user_screen_test.dart
- test/features/users/presentation/pages/user_editor_screen_test.dart
- test/features/users/presentation/pages/user_extended_info_page_test.dart
- test/main/app_test.dart
- test/shared/design_system/theme/semantic_colors_test.dart
- test/shared/design_system/tokens/padding_spacing_test.dart
- test/shared/dynamic_forms/presentation/pages/dynamic_form_page_test.dart
- test/shared/dynamic_forms/presentation/widgets/dynamic_form_renderer_test.dart
- test/shared/widgets/responsive_form_widget_test.dart
- test/shared/widgets/submit_button_widget_test.dart
- test/shared/widgets/web_back_button_disabler_test.dart

- [ ] **Step 1: Prepend the annotation to every file in the list**

At the very top of each file (before the first `import`), insert these two lines followed by a blank line:

```dart
@Tags(['widget'])
library;
```

So a file that currently starts with:
```dart
import 'package:flutter/material.dart';
```
becomes:
```dart
@Tags(['widget'])
library;

import 'package:flutter/material.dart';
```

Do not change anything else in the files.

- [ ] **Step 2: Analyze (catches malformed annotation/library placement)**

Run: `fvm dart analyze`
Expected: `No issues found!`

- [ ] **Step 3: Verify the tag selects exactly these files**

Run: `fvm flutter test --tags widget -r compact 2>&1 | tail -3`
Expected: `All tests passed!` — and the run includes only widget files.

Run: `fvm flutter test --tags widget -r expanded 2>&1 | grep -c "loading "` (optional sanity) — the number of suites loaded should be 29.

- [ ] **Step 4: Verify exclusion works**

Run: `fvm flutter test --exclude-tags widget -r compact 2>&1 | tail -3`
Expected: `All tests passed!` (the ~108 unit/bloc files; no widget files).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "test: tag widget-test files with @Tags(['widget']) (#154)"
```

---

## Task 3: Centralize the CI timeout

**Files:**
- Modify: `.github/workflows/build_and_test.yml`

- [ ] **Step 1: Drop `--timeout=30s` from the test step**

The timeout now lives in `dart_test.yaml`. Change the test command line:

From:
```yaml
        run: flutter test --coverage --timeout=30s --concurrency=4 --reporter=compact
```
To:
```yaml
        run: flutter test --coverage --concurrency=4 --reporter=compact
```

(Leave the rest of the job — `timeout-minutes: 15`, coverage step — unchanged. `sonar_scanner.yml` is unchanged.)

- [ ] **Step 2: Validate YAML structure**

Run: `grep -n "flutter test --coverage" .github/workflows/build_and_test.yml`
Expected: shows the line WITHOUT `--timeout=30s`, with `--concurrency=4 --reporter=compact` intact.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/build_and_test.yml
git commit -m "ci: move per-test timeout into dart_test.yaml (#154)"
```

---

## Task 4: Document the tags

**Files:**
- Modify: `README.md` (Test section)
- Modify: `docs/testing-architecture.md` (Tags/presets bullet under Determinism & known gaps)

- [ ] **Step 1: Add tag commands to README Test section**

In `README.md`, find the `### Test` fenced block (the one with `fvm flutter test` commands) and add these lines inside the code block, after the existing commands:

```shell
# Run only widget tests / everything except widget tests (fast unit loop)
fvm flutter test --tags widget
fvm flutter test --exclude-tags widget
```

And add a sentence after the block:

```markdown
Tags are declared in `dart_test.yaml` (`widget`, plus `golden`/`integration`
reserved for upcoming visual-regression and end-to-end suites).
```

- [ ] **Step 2: Update the Tags/presets bullet in `docs/testing-architecture.md`**

Replace the existing bullet:
```markdown
- **Tags/presets:** there is no `dart_test.yaml` tagging scheme yet (issue #154).
```
with:
```markdown
- **Tags:** `dart_test.yaml` declares `widget` (applied to all `testWidgets`
  files via `@Tags(['widget'])`), plus `golden` and `integration` reserved for
  #135/#152. Slice the suite with `flutter test --tags widget` /
  `--exclude-tags widget`. The per-test timeout (30s) lives in `dart_test.yaml`.
```

- [ ] **Step 3: Commit**

```bash
git add README.md docs/testing-architecture.md
git commit -m "docs: document test tags + run commands (#154)"
```

---

## Task 5: Full verification

- [ ] **Step 1: No-warning full run**

Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | grep -iE "unknown tag|unrecognized" || echo "no tag warnings"`
Expected: `no tag warnings`.

- [ ] **Step 2: Full suite + analyze + format**

Run: `fvm flutter test --concurrency=4 --reporter=compact 2>&1 | tail -2` → `All tests passed!` (1565).
Run: `fvm dart analyze` → `No issues found!`.
Run: `fvm dart format . --line-length=120 --set-exit-if-changed` → exit 0 (if it reformats, `git add -A`).

- [ ] **Step 3: Tag slices**

Run: `fvm flutter test --tags widget -r compact 2>&1 | tail -1` → `All tests passed!`
Run: `fvm flutter test --exclude-tags widget -r compact 2>&1 | tail -1` → `All tests passed!`

- [ ] **Step 4: Commit any formatting**

```bash
git add -A && git commit -m "test: dart_test.yaml tags finalize (#154)" || echo "nothing to commit"
```

---

## Self-review notes

- **Spec coverage:** dart_test.yaml → Task 1; widget tagging → Task 2; CI timeout → Task 3; docs → Task 4; verification → Task 5. All covered.
- **YAGNI:** golden/integration declared but unused (no placeholder tests); ~108 unit files untagged.
- **No placeholders:** full `dart_test.yaml`, exact annotation, full 29-file list, exact CI before/after, exact doc edits.
- **Consistency:** tag names `widget`/`golden`/`integration` identical across config, annotations, CI, docs.
