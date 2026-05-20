# Upgrade Guide — Flutter 3.44.0

**Date:** 2026-05-20
**Flutter:** 3.41.8 → 3.44.0
**Dart:** 3.11.5 → 3.12.0
**App Version:** 0.20.0 → 0.21.0

This guide captures what changed when the template upgraded to Flutter 3.44.0 / Dart 3.12.0 alongside the **enterprise BLoC audit** that shipped in [v0.21.0](https://github.com/cevheri/flutter-bloc-advanced/releases/tag/v0.21.0). If you maintain a fork or a downstream template, use this as a punch list.

> **Full release notes** are on the [v0.21.0 release page](https://github.com/cevheri/flutter-bloc-advanced/releases/tag/v0.21.0).

---

## 1. Toolchain bumps

| Component | Before | After |
| --- | --- | --- |
| Flutter | 3.41.8 | 3.44.0 |
| Dart SDK | ^3.11.5 | ^3.12.0 |
| FVM pin | `3.41.8` | `3.44.0` |

Pin Flutter via [FVM](https://fvm.app):

```bash
fvm install 3.44.0
fvm use 3.44.0
fvm flutter --version   # confirm
```

The repo's `.fvmrc` and `pubspec.yaml` environment constraint already enforce this.

---

## 2. Resolution conflict — `test_api`

Flutter 3.44 SDK pins `test_api: 0.7.11`. The previous `test: 1.30.0` dev-dependency transitively pinned `test_api: 0.7.10` — conflict.

**Fix:** bump `test` to `1.31.0` (or `^1.31.0`). Done in [#126](https://github.com/cevheri/flutter-bloc-advanced/pull/126); your fork needs the same edit if you've pinned `test` to an older version.

---

## 3. Dart 3.12 lint: `prefer_initializing_formals`

Dart 3.12 strengthens `prefer_initializing_formals`. Many constructors written as:

```dart
SomeBloc({required SomeUseCase someUseCase})
  : _someUseCase = someUseCase,
    super(...);
```

now flag at `info` level. Either:
- Use initializing formals where the field name matches the parameter, or
- Accept the info and move on (lints, not errors).

The template's audit chose the initializing-formal style in commit `29d1178` to keep the analyzer clean.

---

## 4. New `ListTile` ↔ `DecoratedBox` assertion (the big one)

Flutter 3.44 introduced a runtime assertion that fires when a `ListTile` finds a coloured `DecoratedBox` between itself and the nearest `Material`:

```
ListTile background color or ink splashes may be invisible.
The ListTile is wrapped in a DecoratedBox that has a background color.
```

This breaks any custom card / form container that uses `Container(decoration: BoxDecoration(color: ...))` and renders a `ListTile` (or `SwitchListTile`, `CheckboxListTile`) underneath. In this template that included:

- `AppFormCard` containing `FormBuilderSwitch` (which renders an internal `SwitchListTile`)
- `AppCard` containing the settings screen's `ListTile`s

### Fix patterns

**`AppFormCard`** — outer `Container(decoration:)` replaced with `Material(shape: ...)`:

```dart
Material(
  color: cs.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    side: BorderSide(color: cs.outlineVariant),
  ),
  clipBehavior: Clip.antiAlias,
  child: ...,
)
```

**`AppCard`** — the `AnimatedContainer` is kept for hover animations; an interior transparent `Material` gives ListTiles their required ancestor:

```dart
AnimatedContainer(
  decoration: _decoration(colorScheme),
  child: Material(
    type: MaterialType.transparency,
    child: Padding(...),
  ),
)
```

If your fork has its own card/list widgets, scan for `Container(decoration: BoxDecoration(color: ...))` ancestors of `ListTile` and apply one of the two patterns above. See [#125](https://github.com/cevheri/flutter-bloc-advanced/pull/125) for the full diff.

---

## 5. Android migrator flags

Running `flutter pub get` under 3.44 auto-injects two opt-out flags into `android/gradle.properties`:

```
android.builtInKotlin=false
android.newDsl=false
```

These opt out of two new AGP behaviours that the template doesn't yet adopt:
- `builtInKotlin` — AGP 8.x's built-in Kotlin support (we still apply `id("kotlin-android")` explicitly).
- `newDsl` — AGP's new DSL surface.

**Commit these flags** so subsequent `pub get` runs don't repeatedly mark the tree dirty. Migration to the new behaviours is a separate future project — out of scope for the Flutter upgrade itself.

---

## 6. Dependency refresh (latest LTS)

After the toolchain settled, we stripped every direct dependency to `any`, ran `flutter pub upgrade`, and re-pinned to the resolved latest. Notable bumps:

| Package | Before | After | Notes |
| --- | --- | --- | --- |
| `go_router` | 17.2.2 | 17.2.3 | patch |
| `flutter_secure_storage` | 10.0.0 | 10.2.0 | minor (+ darwin/windows backends) |
| `package_info_plus` | 9.0.1 | **10.1.0** | **major** — API-compatible at our use site |

Every other direct dep was already on latest. See [#126](https://github.com/cevheri/flutter-bloc-advanced/pull/126).

If your fork uses `package_info_plus` beyond `PackageInfo.fromPlatform()`, check the [10.0 changelog](https://pub.dev/packages/package_info_plus/changelog) for breaking changes — there's a few platform-channel adjustments.

---

## 7. Test impact

- Before fixes: **8 widget tests failed** under Flutter 3.44 due to the `ListTile` assertion (settings + user-editor + user-list pages).
- After the design-system fix: **1417 tests pass**, `dart analyze` clean, `dart format --line-length=120` enforced.

---

## 8. BLoC architecture changes (v0.21.0)

The Flutter upgrade landed alongside an enterprise audit that rewrote substantial parts of the BLoC layer. If you've vendored any of these:

- `UserBloc` was split into `UserListBloc` + `UserEditorBloc` ([#75](https://github.com/cevheri/flutter-bloc-advanced/pull/122))
- `LoginBloc` constructor now requires `persistAuthSessionUseCase` ([#71](https://github.com/cevheri/flutter-bloc-advanced/pull/116))
- `DynamicFormBloc` constructor now requires `loadFormSchemaUseCase` + `submitFormUseCase` ([#72](https://github.com/cevheri/flutter-bloc-advanced/pull/120))
- `AuthorityBloc` constructor takes `ListAuthoritiesUseCase` instead of the repository directly ([#73](https://github.com/cevheri/flutter-bloc-advanced/pull/117))
- `LoginErrorState` and `SettingsFailure` now require a typed `errorCode: AppErrorCode` parameter ([#77](https://github.com/cevheri/flutter-bloc-advanced/pull/118))
- Every error state moved to a Dart 3 sealed hierarchy ([#103–#114](https://github.com/cevheri/flutter-bloc-advanced/releases/tag/v0.21.0))

The full breaking-changes table is in the [v0.21.0 release notes](https://github.com/cevheri/flutter-bloc-advanced/releases/tag/v0.21.0).

---

## Verification checklist

After your upgrade, confirm:

```bash
fvm flutter --version           # 3.44.0
fvm dart --version              # 3.12.0
fvm flutter pub get             # no resolution conflicts
fvm dart analyze                # no issues
fvm flutter test                # all green
fvm flutter build apk --target lib/main/main_prod.dart   # production build OK
```

If anything fails, check this guide's relevant section or open an issue.
