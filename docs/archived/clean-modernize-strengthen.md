# Clean, Modernize, Strengthen — Transformation Report

> **Date:** March 13, 2026
> **Scope:** Phase 1 (CLEAN) + Phase 2 (MODERNIZE) + Phase 3 (STRENGTHEN)
> **Affected files:** 109 (88 modified/deleted + 21 new)
> **Net change:** +1,500 lines added, -3,145 lines removed = **1,645 fewer lines of code**
> **Test results:** 568 tests, 0 failures

---

# Why This Transformation Was Needed

The **flutter_bloc_advance** project was built on a solid foundation, but over time technical debt had accumulated. The project is presented as a SaaS template, yet several issues were weakening its **production-ready** claim.

Examples included:

* A **383-line monolithic HTTP class** containing over 100 lines of commented-out dead code
* Error handling fully based on **exceptions and try/catch**, with no type safety
* The CI pipeline contained `continue-on-error: true`, meaning builds succeeded **even when tests failed**
* **Five unused dependencies** were unnecessarily increasing project weight
* **No tests existed for use cases, mappers, or entities** (0/17 use cases tested)
* Architectural rules were documented only in **CLAUDE.md**, but not enforced in the code

Each issue might appear small individually, but together they reduced the reliability and quality expected from a **production-ready template**.

---

# Previous State of the Project

## HTTP Layer (Before)

```
lib/infrastructure/http/
  http_utils.dart          # 383 lines, SINGLE file
```

* Used the `http` package (basic client, no interceptor support)
* Mock mode, auth token handling, and logging were all mixed inside the same class
* 100+ lines of commented-out code (`// MyHttpOverrides`, `// decodeUTF8`, `// getRequestHeader`, `// returnResponse`)
* Manual `debugPrint` logging in more than 20 places
* Every repository manually added token headers

---

## Error Handling (Before)

```dart
// Repositories returned nullable values
Future<User?> getAccount() async {
  try {
    final response = await HttpUtils.getRequest('/account');
    return User.fromJsonString(response.body);
  } catch (e) {
    return null;  // Error information lost!
  }
}

// BLoC handled null checks
final user = await repository.getAccount();
if (user != null) {
  emit(state.copyWith(status: Status.success, data: user));
} else {
  emit(state.copyWith(status: Status.failure)); // Why failed? Unknown.
}
```

---

## Dependency List (Before)

```yaml
dependencies:
  http: 1.6.0              # Basic HTTP client, no interceptors
  pdf: 3.11.3              # Unused
  printing: 5.14.2         # Unused
  flutter_inappwebview: 6.1.5  # Unused
  glob: 2.1.3              # Unused
  get_storage: 2.1.1       # Conflicts with shared_preferences
```

---

## Storage Layer (Before)

```dart
// Two storage strategies existed, but one (GetStorage) was unused
enum StorageType { sharedPreferences, getStorage }

class GetStorageStrategy implements StorageStrategy { ... }  // Dead code
class SharedPreferencesStrategy implements StorageStrategy { ... }
```

---

## Catalog Feature (Before)

```
lib/features/catalog/     # 236 lines of stub code, no real business logic
  catalog.dart
  navigation/catalog_routes.dart
  presentation/pages/catalog_screen.dart
```

---

## Test Coverage (Before)

| Category                 | Test Count |
| ------------------------ | ---------- |
| Use case tests           | 0 / 17     |
| Mapper tests             | 0 / 3      |
| Entity tests             | 0 / 4      |
| Shared model tests       | 0 / 2      |
| Architecture guard tests | 0          |
| **Total**                | **472**    |

---

## CI Pipeline (Before)

```yaml
# .github/workflows/build_and_test.yml
- name: Run tests
  continue-on-error: true   # Build succeeds even if tests fail
  run: flutter test
```

---

## Web Files (Before)

```
web/
  google66b8a92043c08f67.html   # Google verification (personal)
  BingSiteAuth.xml              # Bing verification (personal)
  yandex_7c51c6a268e7197e.html  # Yandex verification (personal)
  llms.txt                      # Marketing content
  llms-full.txt                 # Marketing content (368 lines)
```

---

# What Was Done

---

# Phase 1: CLEAN — Removing Dead Code

## 1. Removed Unused Dependencies

**File:** `pubspec.yaml`

| Removed                | Reason                                           |
| ---------------------- | ------------------------------------------------ |
| `pdf`                  | Domain-specific, unnecessary for a SaaS template |
| `printing`             | Domain-specific                                  |
| `flutter_inappwebview` | Niche use case, `url_launcher` is sufficient     |
| `glob`                 | Not used anywhere                                |
| `get_storage`          | Redundant with `shared_preferences`              |

**Added:** `dio: ^5.7.0` (replaces `http`)

---

## 2. Simplified the Storage Layer

**File:** `lib/infrastructure/storage/local_storage.dart` (-195 lines)

Changes:

* Removed `GetStorageStrategy` (unused)
* Removed `StorageType` enum
* `AppLocalStorage` now directly uses `SharedPreferences`
* Single, simple storage strategy

---

## 3. Removed the Catalog Feature

**Deleted:** `lib/features/catalog/` (3 files, 236 lines)

Reason:

* It was only a stub without business logic
* The **Users feature already serves as a CRUD reference implementation**
* All router and route references were removed

---

## 4. Cleaned Web Files

Removed **five personal verification files**:

* Google
* Bing
* Yandex
* llms.txt
* llms-full.txt

Updated template placeholders in:

* `index.html`
* `manifest.json`
* `sitemap.xml`
* `humans.txt`

---

## 5. Added Template Configuration

**New file:** `lib/infrastructure/config/template_config.dart`

```dart
class TemplateConfig {
  static const String appName = 'My SaaS App';
  static const String prodApiUrl = 'https://your-api.example.com/api';
  static const String githubRepo = 'https://github.com/your-org/your-repo';
}
```

A developer cloning the template can customize the project simply by editing this file.

---

## 6. Added Missing Domain Interface

**New file:**
`lib/features/users/domain/repositories/authority_repository.dart`

Previously, `AuthorityRepository` was returned as a concrete class from DI.

Clean Architecture rule:
**Upper layers should depend on interfaces, not concrete implementations.**

---

# Phase 2: MODERNIZE — Architectural Improvements

---

## 7. Result Type (Dart 3 Sealed Classes)

**New files**

* `lib/core/result/result.dart`
* `lib/core/errors/app_error.dart`

Before:

```dart
Future<User?> getAccount();
```

After:

```dart
Future<Result<UserEntity>> getAccount();
```

Usage:

```dart
switch (result) {
  case Success(:final data):
    emit(state.copyWith(status: Status.success, data: data));
  case Failure(:final error):
    switch (error) {
      case AuthError():
      case NetworkError():
      case ValidationError():
    }
}
```

Seven error types were defined:

* NetworkError
* AuthError
* ValidationError
* ServerError
* NotFoundError
* TimeoutError
* UnknownError

### Why sealed classes instead of `dartz` or `fpdart`?

* Native **Dart 3 feature**
* No external dependency
* More readable than `Either<Left, Right>`
* Compiler enforces **exhaustive pattern matching**

Affected components:

* 6 repository interfaces
* 6 concrete repositories
* 9 BLoC classes

---

## 8. HTTP Layer Modernization (`http` → `dio`)

Removed:

```
lib/infrastructure/http/http_utils.dart
```

(383 lines, single file with mixed responsibilities)

New architecture:

```
lib/infrastructure/http/
  api_client.dart
  interceptors/
    auth_interceptor.dart
    logging_interceptor.dart
    mock_interceptor.dart
```

Interceptor chain:

```
Request → AuthInterceptor → MockInterceptor → LoggingInterceptor → Response
```

Comparison:

| Feature          | Old (`http`)              | New (`dio`)             |
| ---------------- | ------------------------- | ----------------------- |
| Token management | Manual headers everywhere | Automatic interceptor   |
| Mock mode        | Mixed with business logic | Separate interceptor    |
| Logging          | 20+ debugPrint calls      | Structured interceptor  |
| Error mapping    | try/catch                 | DioException → AppError |
| Timeout          | Manual                    | Configurable            |
| Interceptors     | Not supported             | Native support          |

### Why Dio?

* Powerful interceptor architecture
* FormData support (file uploads)
* Automatic retry capabilities
* Widely used in the Flutter ecosystem

---

## 9. Pagination Abstraction

New file:

```
lib/shared/models/paged_result.dart
```

```dart
class PagedResult<T> extends Equatable {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => (page + 1) * pageSize < totalCount;
  int get totalPages => (totalCount / pageSize).ceil();
}
```

All features can now share the same pagination abstraction.

---

## 10. Environment-Aware Dependency Injection

Updated:

```
lib/app/di/app_dependencies.dart
```

Before:

```dart
IDashboardRepository createDashboardRepository() =>
  DashboardMockRepository();
```

After:

```dart
IDashboardRepository createDashboardRepository() =>
  ProfileConstants.isProduction
    ? DashboardApiRepository()
    : DashboardMockRepository();
```

---

## 11. Model and Entity Simplification

Removed unnecessary mappers:

* `user_mapper.dart`
* `dashboard_mapper.dart`

Reason: models had identical fields to entities.

Now:

```dart
final model = User.fromEntity(entity);
final entity = user; // Model extends Entity
```

Remaining mapper:

* `AuthMapper` (API structure differs from domain structure)

---

# Phase 3: STRENGTHEN — Testing and Quality Gates

---

## 12. CI Pipeline Fixed

Before:

```yaml
continue-on-error: true
```

After:

```yaml
run: fvm flutter test
```

Test failure now **fails the build**.

---

## 13. Added Use Case Tests

17 new test files were created covering:

* Users
* Account
* Auth
* Dashboard
* Settings

Each test includes:

* success scenarios
* failure scenarios
* edge cases

---

## 14. Added Entity, Model, and Mapper Tests

New tests for:

* Auth entities
* Dashboard entities
* Shared models
* Pagination
* Auth mapper

---

## 15. Architecture Guard Tests

New file:

```
test/architecture/import_guard_test.dart
```

These tests enforce architectural rules such as:

* `core/` cannot import from higher layers
* `features/` cannot depend on other feature internals
* `infrastructure/` cannot depend on `features/`

Violations immediately cause test failures.

---

## 16. Pre-Commit Hooks

New script:

```
scripts/setup_hooks.sh
```

Hooks include:

**Pre-commit**

* code formatting
* static analysis

**Pre-push**

* running all tests

---

## 17. Improved Testing Infrastructure

Updated:

```
test/mocks/mock_classes.dart
```

Added:

* interface-level mocks
* fake entity classes
* expanded fallback values

Updated:

```
test/test_utils.dart
```

Added:

* `ApiClient.reset()` for test isolation

---

# Results: Before vs After

| Metric             | Before        | After          | Change       |
| ------------------ | ------------- | -------------- | ------------ |
| Total tests        | 472           | 568            | +96          |
| Use case tests     | 0             | 34             | +34          |
| Entity/model tests | 0             | 37             | +37          |
| Mapper tests       | 0             | 5              | +5           |
| Architecture tests | 0             | 5              | +5           |
| Feature count      | 6             | 5              | -1           |
| Dependencies       | ~21           | ~16            | -5           |
| HTTP layer         | Monolithic    | Modular        | Improved     |
| Dead code          | 100+ lines    | 0              | Clean        |
| Error handling     | Nullable      | Result<T>      | Type-safe    |
| CI reliability     | Tests ignored | Tests enforced | Reliable     |
| Net code change    | —             | —              | -1,645 lines |

---

# Verification

```
fvm dart analyze
✓ No issues found

fvm flutter test
✓ 568 tests, 0 failures

fvm dart format .
✓ Formatting OK
```

---

# Next Steps (Phases 4–6)

| Phase   | Scope                                         | Status  |
| ------- | --------------------------------------------- | ------- |
| Phase 4 | Notifications, Onboarding, Audit Log features | Planned |
| Phase 5 | Mason scaffolding, Widgetbook, Makefile       | Planned |
| Phase 6 | GitHub templates, roadmap, ADR documentation  | Planned |

For the detailed roadmap see:

**Transformation Plan**

```
clean-modernize-strengthen-plan.md
```
