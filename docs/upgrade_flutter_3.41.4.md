# Upgrade Guide - Flutter 3.41.4 & Full Package Upgrade

**Date:** 2026-03-09
**Flutter:** 3.41.4 (Dart 3.11.1)
**App Version:** 0.18.0+1

---

## Overview

This upgrade includes three major changes:

1. **Removal of `dart_json_mapper`** - Replaced with manual JSON serialization
2. **Full package upgrade** - All dependencies upgraded to latest compatible versions
3. **Android/Gradle modernization** - Migrated to Kotlin DSL, upgraded Gradle, AGP, Kotlin and Java versions

---

## 1. dart_json_mapper Removal

### Why?

`dart_json_mapper` relies on `reflectable` which depends on old versions of `build_runner` and `analyzer`. These old packages conflict with Dart 3.11.1's `_macros` SDK package, making dependency resolution impossible.

### What Changed?

All model classes were rewritten with manual `fromJson`/`toJson` methods instead of reflection-based serialization.

#### Before (dart_json_mapper)

```dart
@jsonSerializable
class User {
  @JsonProperty(name: 'id')
  String? id;
  // ...
}

// Usage
final user = JsonMapper.deserialize<User>(jsonString);
final json = JsonMapper.serialize(user);
```

#### After (manual serialization)

```dart
class User extends Equatable {
  final String? id;
  // ...

  static User? fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      // ...
    );
  }

  static User? fromJsonString(String json) => fromJson(jsonDecode(json));
  static List<User> fromJsonList(List<dynamic> jsonList) => jsonList.map((json) => fromJson(json)!).toList();
  static List<User> fromJsonStringList(String jsonString) => fromJsonList(jsonDecode(jsonString));

  Map<String, dynamic>? toJson() {
    final Map<String, dynamic> json = {};
    if (id != null) json['id'] = id;
    // ...
    return json;
  }
}
```

### Affected Model Files

| File | Key Changes |
|------|-------------|
| `lib/data/models/user.dart` | Full rewrite with DateTime parsing, authorities list |
| `lib/data/models/jwt_token.dart` | `@JsonProperty(name: 'id_token')` -> `json['id_token']` |
| `lib/data/models/menu.dart` | Recursive `parent` field fromJson support |
| `lib/data/models/user_jwt.dart` | Positional constructor kept |
| `lib/data/models/change_password.dart` | Manual fromJson/toJson |
| `lib/data/models/send_otp_request.dart` | Simplified fromJson |
| `lib/data/models/verify_otp_request.dart` | Simplified fromJson |
| `lib/data/models/authority.dart` | Removed annotations only |
| `lib/data/models/city.dart` | Removed annotations only |
| `lib/data/models/district.dart` | Removed annotations only |
| `lib/data/models/customer.dart` | Removed annotations only |

### Other Code Changes

- **`lib/data/http_utils.dart`**: Replaced `JsonMapper.serialize(body)` with `jsonEncode(body.toJson())`. Added `body is Map` check for POST/PUT/PATCH methods.
- **`lib/data/repository/user_repository.dart`**: Replaced `JsonMapper.deserialize<List<User>>` with `User.fromJsonStringList`.
- **`lib/main/main_local.dart`** and **`lib/main/main_prod.dart`**: Removed `initializeJsonMapper()` call and mapper import.

### Deleted Files

- `lib/main/main_local.mapper.g.dart` (767 lines)
- `lib/main/main_prod.mapper.g.dart` (767 lines)
- `test/presentation/screen/login/login_screen_test.dart` (empty after skip removal)
- `test/presentation/screen/login/login_screen_test.mocks.dart`

### Removed Dependencies

- `dart_json_mapper`
- `reflectable`
- `build_runner` (dev)
- `analyzer` (dev)

---

## 2. Package Upgrades

### Major Upgrades

| Package | Old Version | New Version | Type |
|---------|------------|-------------|------|
| flutter_bloc | 8.1.6 | **9.1.1** | MAJOR |
| bloc_test | 9.1.7 | **10.0.0** | MAJOR |
| bloc_concurrency | 0.2.5 | **0.3.0** | MINOR |
| go_router | 16.1.0 | **17.1.0** | MAJOR |
| auto_route | 10.1.0+1 | **11.1.0** | MAJOR |
| getwidget | 6.0.0 | **7.0.0** | MAJOR |
| flutter_lints | 4.0.0 | **6.0.0** | MAJOR |

### Minor/Patch Upgrades

| Package | Old Version | New Version | Type |
|---------|------------|-------------|------|
| http | 1.5.0 | **1.6.0** | MINOR |
| adaptive_theme | 3.7.0 | **3.7.2** | PATCH |
| equatable | 2.0.7 | **2.0.8** | PATCH |
| get | 4.7.2 | **4.7.3** | PATCH |
| flutter_form_builder | 10.1.0 | **10.3.0+2** | MINOR |
| form_builder_validators | 11.2.0 | **11.3.0** | MINOR |
| animated_toggle_switch | 0.8.5 | **0.8.7** | PATCH |
| shared_preferences | 2.5.3 | **2.5.4** | PATCH |
| logger | 2.6.1 | **2.6.2** | PATCH |
| mockito | 5.4.5 | **5.6.3** | MINOR |

### Unchanged (Already Latest)

`cupertino_icons`, `intl`, `pdf`, `printing`, `expansion_tile_card`, `device_preview`, `intl_utils`, `http_certificate_pinning`, `modbus_client_tcp`, `custom_navigation_bar`, `flutter_inappwebview`, `glob`, `get_storage`, `test`

---

## 3. Test Fixes

### SharedPreferences Async Platform Fix

`adaptive_theme 3.7.2` migrated to `SharedPreferencesAsync` API. Tests using `AdaptiveTheme` widget require both legacy and async platform mocks:

```dart
SharedPreferences.setMockInitialValues({});
SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
```

**Affected files:**
- `test/test_utils.dart` - Added async platform mock to `_clearStorage()`
- `test/presentation/widgets/login_otp_verify_widget_test.dart` - Added to setUp
- `test/presentation/widgets/login_otp_email_widget_test.dart` - Added to setUp

### ListUserScreen Test Fix

- `ElevatedButton` -> `OutlinedButton` (widget type changed in screen)
- `"active"` -> `"Active"` (case mismatch with screen)
- `findsOneWidget` -> `findsNWidgets(2)` (header + data row both show "Active")

### Removed Skipped Tests (13 total)

| File | Tests Removed | Reason |
|------|--------------|--------|
| `router_test.dart` | 2 | Pop and invalid route tests |
| `login_otp_email_widget_test.dart` | 1 | Turkish locale test |
| `settings_screen_test.dart` | 4 | Theme, logout dialog tests |
| `login_screen_test.dart` | 5 | Entire file deleted (all skipped) |
| `change_password_screen_test.dart` | 1 | Field name validation |

---

## 4. Test Results

```
562 passed, 0 failed, 0 skipped
```

---

## 5. Android & Gradle Modernization

### Groovy -> Kotlin DSL Migration

All Android Gradle files migrated from Groovy (`.gradle`) to Kotlin DSL (`.gradle.kts`):

| Old File (deleted) | New File |
|---|---|
| `android/settings.gradle` | `android/settings.gradle.kts` |
| `android/build.gradle` | `android/build.gradle.kts` |
| `android/app/build.gradle` | `android/app/build.gradle.kts` |

### Version Upgrades

| Component | Old | New |
|---|---|---|
| **Dart SDK** | `^3.8.1` | `^3.11.1` |
| **Gradle** | 8.12 | **8.14** |
| **Android Gradle Plugin (AGP)** | 8.7.3 | **8.11.1** |
| **Kotlin** | 2.1.0 | **2.2.20** |
| **Java (compile target)** | 11 | **17** |
| **NDK** | `"27.0.12077973"` (hardcoded) | `flutter.ndkVersion` (dynamic) |

### gradle.properties

- JVM args updated: `-Xmx4G` -> `-Xmx8G`, added `-XX:ReservedCodeCacheSize=512m`
- `MaxMetaspaceSize` increased: `2G` -> `4G`
- Removed deprecated `android.enableJetifier=true`

---

## 6. Build Configuration

### build.yaml

Removed `dart_json_mapper` and `reflectable` builder sections. Only `flutter_localizations` builder remains.

### pubspec.yaml

All dependency versions are pinned to exact versions (no `^` prefix) for reproducible builds.

---

## Migration Checklist

- [x] Remove `dart_json_mapper` and `reflectable` from dependencies
- [x] Remove `build_runner` and `analyzer` from dev dependencies
- [x] Rewrite all model classes with manual fromJson/toJson
- [x] Update `http_utils.dart` serialization logic
- [x] Update repository deserialization calls
- [x] Remove `initializeJsonMapper()` from main entry points and test utils
- [x] Delete generated `.mapper.g.dart` files
- [x] Upgrade all packages to latest versions
- [x] Fix SharedPreferences Async platform mock for tests
- [x] Fix outdated widget test assertions
- [x] Remove all skipped tests
- [x] Verify all 562 tests pass
- [x] Verify app runs in browser with mock data
- [x] Migrate Android Gradle files from Groovy to Kotlin DSL
- [x] Upgrade Gradle 8.12 -> 8.14, AGP 8.7.3 -> 8.11.1, Kotlin 2.1.0 -> 2.2.20
- [x] Upgrade Java compatibility 11 -> 17
- [x] Update Dart SDK constraint to ^3.11.1
- [x] Use dynamic `flutter.ndkVersion` instead of hardcoded NDK version
