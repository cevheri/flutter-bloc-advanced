# Upgrade Guide: Flutter 3.47.7

**Date:** 2026-10-20
**Flutter:** 3.44.3 → 3.47.7
**Dart:** 3.12.2 → 3.13.5
**DevTools:** 2.57.0 → 2.60.0
**App Version:** 0.22.1 → 0.22.2

This guide lists what changed when the template moved to Flutter 3.47.7, the latest stable release on 2026-10-20.
If you maintain a fork, use it as a punch list.
Flutter 3.45 and 3.46 were beta-only, so 3.47.0 is the stable release that carries every change from that window, and 3.47.1 to 3.47.7 are hotfixes on top of it.

## 1. Toolchain

| Component | Before | After |
| --- | --- | --- |
| Flutter | 3.44.3 | 3.47.7 |
| Dart SDK constraint | ^3.12.2 | ^3.13.5 |
| pubspec `environment.flutter` | `'3.44.3'` | `'3.47.7'` |
| FVM pin | `3.44.3` | `3.47.7` |
| CI `flutter-version` | `3.44.3` | `3.47.7` |

```bash
fvm install 3.47.7
fvm use 3.47.7
fvm flutter --version   # Flutter 3.47.7, Dart 3.13.5
```

Raising the SDK lower bound to `^3.13.5` matches the 3.47.7 `flutter create` template; Dart 3.13.5 first shipped in Flutter 3.47.6.
Together with the exact `environment.flutter: '3.47.7'` pin, the project resolves only on Flutter 3.47.7.
The only new language feature at 3.13 is primary constructors; this upgrade does not adopt them.
The bundled formatter moves from dart_style 3.1.6 to 3.1.13, and at language 3.13 it separates `package:` imports from relative imports (dart_style #1120) and splits single-element call chains differently (dart_style #1732).
Run `fvm dart format . --line-length=120` once after the bump; here it rewrote 44 files.
Even without the SDK bump, the new formatter adds a blank line after the shebang in `tool/generate_feature.dart` (dart_style #1831, not tied to the language version), so the CI format check fails until the tree is reformatted.
`lib/generated/l10n.dart` was regenerated with `fvm dart run intl_utils:generate` and then formatted, not edited by hand.

`flutter pub get` on 3.47.7 appends `build/**` and the platform folders to `analyzer.exclude` in `analysis_options.yaml`.
Commit that change so later runs do not dirty the tree again.

The root `.gitignore` gains `.build/`, `.swiftpm/` and `.widget_preview/`, and `android/.gitignore` gains `.cxx/`, as in the 3.47.7 template.

## 2. Resolution changes forced by the SDK

- `flutter_localizations` 3.47.7 requires `intl ^0.20.3`, so `intl` moves from 0.20.2 to 0.20.3.
- `flutter_test` 3.47.7 pins `test_api 0.7.12`, which the old exact `test: 1.31.0` dev dependency (`test_api 0.7.11`) cannot satisfy.
  Nothing in the repo imports `package:test`, so the direct dependency was removed; `bloc_test` still brings it in transitively, and pub picks the version that matches the SDK pin.

Without these two changes `flutter pub get` fails on 3.47.7.

## 3. Golden tests

36 of the 60 alchemist CI goldens fail on 3.47.7 and were regenerated with `fvm flutter test --tags golden --update-goldens`.
The cause is engine PR [flutter/flutter#186203](https://github.com/flutter/flutter/pull/186203), first shipped in 3.47.0.
It makes DisplayList draw a uniform `drawDRRect` border as a stroked rounded rectangle, which only changes the anti-aliasing of bordered rounded corners: `BoxDecoration` with `Border.all` plus `borderRadius`, and `RoundedRectangleBorder` with a `side`.

What was checked before regenerating:

- Every changed pixel is an anti-aliased edge pixel: image sizes are unchanged, the largest channel delta is 86/255 and no pixel changed by 128 or more.
- Patching the three framework call sites back to the old even-odd path makes all 60 old goldens pass on 3.47.7, so no other rendering change is involved.
- The per-golden pixel diffs are identical before and after the dependency upgrades in this guide, so none of the package majors changes a golden.

The regenerated goldens only pass on 3.47.x.
Move every CI `flutter-version` pin in the same change.

## 4. Dependencies

| Package | Before | After | Notes |
| --- | --- | --- | --- |
| `go_router` | 17.3.0 | 18.1.0 | major; needs explicit pages, see 5.1 |
| `sentry_flutter` | 9.22.0 | 10.1.0 | major; Android minSdk 26, Apple builds use SwiftPM only, see 5.3 |
| `flutter_secure_storage` | 10.3.1 | 11.2.0 | major; no code change, see 5.4 |
| `equatable` | 2.0.8 | 3.0.0 | major; no code change |
| `shimmer` | 3.0.0 | 4.0.0 | major; no code change, renders pixel-identically |
| `cupertino_icons` | 1.0.9 | 2.0.0 | major; asset-only, same font |
| `dio` | 5.9.2 | 5.11.1 | needs two code changes, see 5.2 |
| `logger` | 2.7.0 | 2.8.0 | |
| `uuid` | 4.5.3 | 4.6.0 | |
| `stream_transform` | 2.1.1 | 2.1.2 | |
| `shared_preferences` | 2.5.5 | 2.5.6 | |
| `url_launcher` | 6.3.2 | 6.3.3 | |
| `package_info_plus` | 10.1.0 | 10.2.2 | |
| `connectivity_plus` | 7.1.1 | 7.3.2 | |
| `screen_protector` | 1.5.1 | 1.5.3 | Dart, Android and iOS plugin code unchanged; adds a Swift package and needs built-in Kotlin on AGP 9, see section 6 |
| `intl` | 0.20.2 | 0.20.3 | required by the SDK |
| `intl_utils` | 2.8.15 | 2.8.17 | moved to `dev_dependencies`; discontinued upstream, see section 8 |
| `alchemist` | ^0.14.0 | 0.14.1 | now an exact pin like every other dependency |

Transitive packages were refreshed with `fvm flutter pub upgrade`.

Removed because nothing imports them:

- `cached_network_image` was never imported; it also pulled in `sqflite` and its native plugins.
- `device_preview` was never imported.
- `fl_chart` has had no import since commit bb79b31, and every published version caps `equatable` at 2.x, which blocked `equatable` 3.0.0.
- The direct `test` dev dependency was never imported either, and its exact pin is what broke `flutter pub get`, see section 2.

Held back on purpose:

| Package | Pinned | Latest | Reason |
| --- | --- | --- | --- |
| `flutter_form_builder` | 10.3.0+2 | 11.0.0 | 11.x is built on `material_ui` and only works in an app migrated to it, see section 8 |

`jni` and `shared_preferences_android` stay below their latest versions because `sentry_flutter` 10.1.0 caps `jni` below 1.1.0.

## 5. Code changes

### 5.1 go_router 18 and material_ui

Flutter 3.47 publishes Material and Cupertino as the standalone packages `material_ui` and `cupertino_ui`.
The SDK copies in `package:flutter/material.dart` and `cupertino.dart` are frozen but not deprecated in 3.47.7.
The two are distinct libraries, so their `MaterialApp`, `MaterialPage` and `ThemeData` classes are not interchangeable.

go_router 18 detects the app type through `material_ui`'s `MaterialApp`.
Under the SDK `MaterialApp.router` that this template uses, every `builder:` route silently becomes a `NoTransitionPage`: no page transition, no iOS back swipe, no Android predictive back.
An unknown location shows go_router's unstyled widgets-only error screen.
Nothing fails at compile time and the existing tests passed, so this regression is silent.

The fix keeps the 17.x behavior:

- `appPlatformPage()` in `lib/shared/design_system/components/app_page_transition.dart` builds the same `MaterialPage` go_router 17 built for `builder:` routes, with one intentional difference.
  It does not copy path and query parameters into the page arguments: nothing reads them, and Sentry's navigator observer would otherwise send values such as the email in `/login-otp-verify/:email` with every error event.
- The shell route, `/forbidden` and the five public auth routes use `pageBuilder: (context, state) => appPlatformPage(...)`.
- `GoRouter.errorPageBuilder` renders the new `NotFoundPage` (`lib/app/router/not_found_page.dart`), a copy of go_router 17's Material error screen.
- `test/app/router/app_router_pages_test.dart` pins the page types, the push transition, the iOS back swipe, the 404 page and the empty page arguments, and fails if any route goes back to `builder:`.

The only remaining difference is that go_router's internal `HeroController` uses a straight tween instead of the Material arc; the app has no `Hero` widgets.
go_router 18.0.2 also wraps shell navigators in `Semantics(container: true)`, so the sidebar and top bar are now in the semantics tree on desktop.

### 5.2 dio 5.10 and later

- The new `DioExceptionType.transformTimeout` makes exhaustive switches fail to compile.
  `ApiClient` maps it to the existing timeout error, and `ResilienceInterceptor` treats it as non-retryable because the server has already answered.
  Both mappings are covered by new tests.
- `ErrorInterceptorHandler.reject` gained an optional `callFollowingErrorInterceptor` parameter, so the three test handlers that override it were updated.
- dio's `dart:io` adapter now reports "connection closed before full header was received" as a `connectionError` instead of `unknown`.
  The server may already have processed that request, and `ResilienceInterceptor` retries connection errors for every HTTP method, so a sign-in or any other POST was sent four times.
  `ResilienceInterceptor` now keeps the dio 5.9 outcome and does not retry this case; other connection errors are still retried.
  On web the browser reports the same failure as a generic network error, which was retried before the upgrade and still is.
- Behavior note, no action needed: async interceptor exceptions now reject the request instead of hanging it.

### 5.3 sentry_flutter 10

- The Android library requires API 26, so `android/app/build.gradle.kts` sets `minSdk = maxOf(flutter.minSdkVersion, 26)`.
  The plugin is always linked, so this drops Android 7.0 and 7.1 for every build, including builds without a DSN.
- iOS and macOS builds use Swift Package Manager only; CocoaPods support was removed in 10.0.0.
- The default trace lifecycle is now streamed spans.
  The `beforeSend` scrubber (`lib/infrastructure/analytics/sentry_scrub.dart`) still runs for every error event; transactions never went through it in 9.x either.
  Scope tags set through `setUserProperty` still reach error events but no longer reach spans.

### 5.4 flutter_secure_storage 11

No code change is needed: the removed Android options were never used, and 11.x reads data written by 10.x as-is.
11.x can no longer read data that was written with the pre-10.x Android ciphers and never migrated by a 10.x build, so an install that skips every 10.x release has to sign in again.
The dead `flutter_secure_storage:` block in `pubspec.yaml` was removed; nothing reads it.

## 6. Android

Flutter 3.47.7 prints "support will soon be dropped" for Gradle below 9.1.0, AGP below 9.0.1 and Kotlin below 2.3.20, and the template sat exactly on the error floor (Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20).
The Android project now follows the 3.47.7 template:

| Item | Before | After |
| --- | --- | --- |
| Android Gradle Plugin | 8.11.1 | 9.1.0 |
| Kotlin Gradle Plugin | 2.2.20 | 2.4.0 |
| Gradle wrapper | 8.14 | 9.3.1 |
| Kotlin JVM target | `kotlinOptions { jvmTarget }` | `kotlin { compilerOptions { jvmTarget } }` |
| `id("kotlin-android")` in `app/build.gradle.kts` | applied | removed, as in the template |
| `minSdk` | `flutter.minSdkVersion` (24) | `maxOf(flutter.minSdkVersion, 26)` |
| `android.builtInKotlin` | `false` | `true` |

Built-in Kotlin goes one step further than the template, which still sets `android.builtInKotlin=false`.
Flutter 3.47 supports turning it on once the app and every plugin have migrated, AGP 9 deprecates the opt-out, and AGP 10 removes it.
Every plugin in the lock supports it once `screen_protector` is on 1.5.3, while 1.5.1 applies the Kotlin Gradle plugin unconditionally and fails with built-in Kotlin on.
Keep the `android.builtInKotlin=true` line: if it is missing, Flutter's migrator appends `android.builtInKotlin=false` again.
A plugin added later that still applies the Kotlin Gradle plugin fails the build until it is updated.

`android.newDsl` stays `false`, because the Flutter Gradle plugin itself does not support the new AGP DSL yet ([flutter/flutter#180137](https://github.com/flutter/flutter/issues/180137)).

The build still prints "Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): screen_protector".
This is a false positive: Flutter's check matches the `apply plugin: 'kotlin-android'` line, which `screen_protector` 1.5.3 only runs on AGP 8 and older, and the build would fail with built-in Kotlin on if the plugin really applied it.

AGP 9.1 lets R8 repackage classes into the default package.
The release APK and AAB build cleanly, but smoke-test a release build on a device: app start with Sentry, sign-in and token storage, screen protection and URL launching.

Android Studio 2026.2 bundles JDK 25, and Flutter uses that JDK for Gradle.
Gradle 8.14 cannot run on JDK 25, so local release builds on the old toolchain fail with `IllegalArgumentException: 25.0.x`.
Gradle 9.3.1 runs on JDK 17 to 25, so CI keeps Temurin 17 and the local JDK 25 works too.

The Play Store requirements in force are met: the target API is 36, and the release APK keeps its native libraries aligned for 16 KB pages.

## 7. iOS and macOS

These edits match what the Flutter 3.47.7 migrators apply on the first Mac build: deployment targets, UIScene, GPU validation and secure restorable state.
`STRING_CATALOG_GENERATE_SYMBOLS = YES` is the exception: it comes from the 3.47.7 `flutter create` template, and no migrator adds it.
They were applied on Linux because CI never builds Apple targets.
**They are not verified on Apple hardware.**

- iOS deployment target 12.0 → 15.0 and macOS 10.14 → 12.0.
  Flutter 3.47 supports iOS 15+ and macOS 12+, Xcode 27 rejects lower targets, and `sentry_flutter` 10 requires them.
  `AppFrameworkInfo.plist` drops its `MinimumOSVersion`, and the Podfile platform lines follow.
- UIScene lifecycle: `AppDelegate` implements `FlutterImplicitEngineDelegate` and `Info.plist` declares a `UIApplicationSceneManifest` with `FlutterSceneDelegate`.
  Apps built with Xcode 27 that have not adopted UIScene fail to launch, and App Store uploads require the iOS 27 SDK from April 2027.
  `screen_protector` still registers only application-lifecycle callbacks; the 3.47.7 engine forwards scene events to such plugins (`sceneWillResignActiveFallback` in `FlutterPluginAppLifeCycleDelegate.mm`), so the task-switcher blur keeps working.
- `STRING_CATALOG_GENERATE_SYMBOLS = YES` (new in the 3.47 template), the GPU validation scheme flag, and `applicationSupportsSecureRestorableState` on macOS.

Swift Package Manager is on by default, and with `screen_protector` 1.5.3 every iOS and macOS plugin in the lock ships a Swift package.
Run these once on a Mac with Flutter 3.47.7, review that the diff only adds the template's SwiftPM wiring and the LLDB init file entries in the iOS scheme, then commit it:

```bash
fvm flutter build ios --config-only --no-codesign --debug
fvm flutter build macos --config-only --debug
```

The Podfiles stay for now, because removing CocoaPods should be checked on a Mac first; `ios/Podfile.lock` is stale and is regenerated by that first build.

The App Store rules in force are met: the deployment target is now 15.0, above the required iOS 13, and release builds need a Mac with Xcode 26 or newer.

## 8. Follow-ups not done in this upgrade

- **material_ui / cupertino_ui migration.**
  Flutter plans to deprecate the SDK Material and Cupertino libraries in the November 2026 stable.
  `dart fix --apply --code=migrate_design_widgets` rewrites the imports in about 150 files and adds `material_ui` and `cupertino_ui` to `pubspec.yaml`, but the migration also needs localization delegate changes, `flutter_form_builder` 11, and an `alchemist` release that accepts `material_ui` themes (alchemist issue #183).
  Do it as one dedicated change; `appPlatformPage()` stays correct after it.
- **intl_utils is discontinued.**
  2.8.17 still works on Dart 3.13.
  The replacement is Flutter's built-in `gen-l10n`, which touches 4 lib files and 18 test files and changes how the active locale is resolved.
- **Apple verification.**
  Build and launch iOS and macOS once on a Mac, commit the SwiftPM wiring, and then decide whether to drop the Podfiles.
- **Release smoke test on an Android device**, because of the R8 repackaging in AGP 9.1 (section 6).

## Verification

```bash
fvm flutter --version                    # 3.47.7 / Dart 3.13.5
fvm flutter pub get                      # resolves without conflicts
fvm flutter analyze                      # No issues found
fvm dart format . --line-length=120 --set-exit-if-changed
fvm flutter test --coverage              # all tests pass, coverage above the 65% gate
fvm flutter build apk --release --target lib/main/main_prod.dart
fvm flutter build appbundle --release --target lib/main/main_prod.dart
fvm flutter build web --release --base-href /flutter-bloc-advanced/ --target lib/main/main_local.dart
```
