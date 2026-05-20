# Release Notes - v0.19.0 / v0.19.1

## Feature-First Clean Architecture Migration

**Tag:** v0.19.1
**Date:** March 2026
**Branch:** `feat/feature-first-clean-arch`
**Type:** BREAKING CHANGE

---

## Summary

Complete architectural migration from **Layered (Horizontal) Architecture** to **Feature-First Clean Boundaries Architecture**. This release restructures the entire codebase into self-contained feature modules, introduces the Use Case pattern, replaces mockito with mocktail, removes code generation dependencies, and aligns the test structure with the new architecture.

---

## Highlights

- Layered architecture -> Feature-first clean boundaries
- 6 isolated feature modules: `account`, `auth`, `catalog`, `dashboard`, `settings`, `users`
- Use Case pattern: BLoC -> UseCase -> Repository Interface
- mockito -> mocktail migration (57 generated `.mocks.dart` files removed)
- build_runner, json_serializable, auto_route removed
- 44 dead code files eliminated (city, district, customer modules)
- Test folder restructured to mirror `lib/` feature-first layout
- 472 tests passing, 0 failures, 0 analyzer issues

---

## Architecture: Before vs After

### Before (Layered)

```
lib/
├── configuration/          # All config in one place
├── data/
│   ├── models/             # ALL models together
│   └── repository/         # ALL repositories together
├── presentation/
│   ├── common_blocs/       # ALL BLoCs together
│   ├── common_widgets/
│   ├── design_system/
│   ├── screen/             # Screens grouped by feature but BLoCs separate
│   └── shell/
├── routes/                 # All routing config
└── utils/                  # All utilities
```

### After (Feature-First)

```
lib/
├── app/                    # Composition root
│   ├── bootstrap/          # App startup
│   ├── di/                 # Dependency injection
│   ├── localization/       # Language management
│   ├── router/             # Centralized routing (composes feature routes)
│   ├── session/            # Auth session cubit
│   ├── shell/              # App shell (sidebar, top bar, bottom nav, drawer, command palette)
│   └── theme/              # Theme BLoC
├── core/                   # Cross-cutting primitives (zero dependencies)
│   ├── errors/
│   ├── logging/
│   ├── security/
│   └── testing/
├── features/               # 6 self-contained business modules
│   ├── account/
│   ├── auth/
│   ├── catalog/
│   ├── dashboard/
│   ├── settings/
│   └── users/
├── infrastructure/         # External adapters
│   ├── config/             # Environment, constants
│   ├── http/               # HTTP client
│   └── storage/            # Local storage
├── shared/                 # Business-free reusable components
│   ├── design_system/      # 14 components, tokens, theme
│   ├── models/             # Cross-feature entities (UserEntity)
│   ├── utils/              # Generic utilities
│   └── widgets/            # Reusable form widgets
├── generated/              # Auto-generated localization
├── l10n/                   # ARB translation files (en, tr)
└── main/                   # Entry points
```

### Feature Module Structure

Each feature follows a standardized 5-layer internal structure:

```
features/<feature>/
├── application/            # BLoCs + Use Cases
│   ├── <feature>_bloc.dart
│   ├── <feature>_event.dart
│   ├── <feature>_state.dart
│   └── usecases/
├── data/                   # Models, Mappers, Repository implementations
│   ├── models/
│   ├── mappers/
│   └── repositories/
├── domain/                 # Interfaces (Flutter-free)
│   ├── entities/
│   └── repositories/
├── navigation/             # Feature-specific routes
└── presentation/           # Pages and feature-local widgets
    ├── pages/
    └── widgets/
```

---

## Dependency Rules

```
app            -->  features, shared, infrastructure, core
features       -->  shared, infrastructure, core
shared         -->  core only
infrastructure -->  core only
core           -->  nothing
```

- Features CANNOT import from other features' internal directories.
- Cross-feature models/widgets MUST live in `shared/`.
- 0 boundary violations detected.

---

## Breaking Changes

### Removed Packages

| Package | Reason |
|---------|--------|
| `build_runner` | No code generation needed (manual fromJson/toJson) |
| `json_serializable` | Replaced with manual serialization + Equatable |
| `mockito` | Replaced with `mocktail` |
| `auto_route` | Fully migrated to `go_router` |

### New Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `mocktail` | ^1.0.4 | Simplified mock management without code generation |

### Removed Modules (Dead Code)

| Module | Files Removed | Reason |
|--------|---------------|--------|
| City (BLoC + Model + Repository) | 6 | Unused |
| District (BLoC + Model + Repository) | 6 | Unused |
| Customer (Screen + BLoC + Model + Repository) | 11 | Empty BLoC, unused screens |
| Home Screen (legacy) | 1 | 0 imports |
| utils/message.dart | 1 | 0 imports |
| utils/storage.dart | 1 | Entirely commented-out code |
| top_actions_widget.dart | 1 | 0 imports |
| drawer_widget.dart (legacy) | 1 | 0 imports |
| Mock JSON files | 5 | Belonged to removed modules |
| Related test files | 11 | Belonged to removed modules |
| **Total** | **~44 files** | |

### Import Path Changes

All imports changed from layered paths to feature-first paths:

```dart
// Before
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user_bloc.dart';

// After
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';
```

---

## Added

### Use Case Pattern

BLoCs now depend on use cases instead of directly on repositories:

```dart
// Before
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository repository;
  LoginBloc({required this.repository});
}

// After
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required AuthenticateUserUseCase authenticateUserUseCase,
    required SendOtpUseCase sendOtpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required GetAccountUseCase getAccountUseCase,
  });
}
```

**17 use cases** implemented across all features.

### Centralized Dependency Injection

```dart
// lib/app/di/app_dependencies.dart - Repository factories
class AppDependencies {
  IAccountRepository createAccountRepository() => AccountRepository();
  IAuthRepository createAuthRepository() => LoginRepository();
  IUserRepository createUserRepository() => UserRepository();
  // ...
}

// lib/app/di/app_scope.dart - BLoC providers composition root
```

### Feature Route Composition

```dart
// lib/app/router/app_router.dart
ShellRoute(
  builder: (context, state, child) => AppShell(state: state, child: child),
  routes: [
    ...DashboardFeatureRoutes.routes,
    ...AccountFeatureRoutes.routes,
    ...UsersFeatureRoutes.routes,
    ...SettingsFeatureRoutes.routes,
    ...CatalogFeatureRoutes.routes,
  ],
),
...AuthFeatureRoutes.routes,  // Outside shell (no auth required)
```

---

## Changed

### Test Infrastructure: mockito -> mocktail

**Commit:** `09b4ea8`

| Metric | Before | After |
|--------|--------|-------|
| Mock framework | mockito + build_runner | mocktail |
| Generated `.mocks.dart` files | 57 | 0 |
| Mock definition | `@GenerateMocks([...])` annotation | Manual `class MockX extends Mock implements X` |
| Stub syntax | `when(mock.method()).thenReturn(...)` | `when(() => mock.method()).thenReturn(...)` |
| Central mock file | None (scattered) | `test/mocks/mock_classes.dart` |

### Test Folder Structure

Test directory restructured to mirror `lib/` feature-first layout:

```
test/
├── app/                    # app/ tests
│   ├── di/                 # DI contract tests
│   ├── localization/       # Localization tests
│   ├── router/             # Router tests
│   └── shell/              # Shell & drawer bloc tests
│       └── models/
├── core/                   # core/ tests
│   ├── constants/
│   ├── logging/
│   └── security/
├── features/               # Feature tests (mirrors lib/features/)
│   ├── account/
│   │   ├── application/    # AccountBloc tests
│   │   ├── data/           # Repository & model tests
│   │   └── presentation/   # Page widget tests
│   ├── auth/
│   │   ├── application/    # Login, Register, ForgotPassword, ChangePassword bloc tests
│   │   ├── data/           # JWT, OTP model tests, LoginRepository tests
│   │   └── presentation/   # Login, Register, ForgotPassword page tests
│   ├── dashboard/
│   │   ├── application/    # DashboardCubit tests
│   │   ├── navigation/     # Route tests
│   │   └── presentation/   # Dashboard & home page tests
│   ├── settings/
│   │   ├── application/    # SettingsBloc tests
│   │   ├── navigation/     # Route tests
│   │   └── presentation/   # Settings page tests
│   └── users/
│       ├── application/    # UserBloc, AuthorityBloc tests
│       ├── data/           # User, Authority model & repository tests
│       ├── navigation/     # Route tests
│       └── presentation/   # UserList, UserEditor page tests
├── infrastructure/         # infrastructure/ tests
│   ├── config/             # Environment tests
│   ├── http/               # HTTP utils tests
│   └── storage/            # LocalStorage tests
├── shared/                 # shared/ tests
│   ├── design_system/
│   │   └── tokens/         # Spacing token tests
│   └── widgets/            # Shared widget tests
├── mocks/                  # Centralized test infrastructure
│   ├── mock_classes.dart   # All mock definitions (mocktail)
│   └── fake_data.dart      # Fake data generators
├── main/                   # App integration tests
└── test_utils.dart         # Shared setup/teardown utilities
```

---

## Migration Statistics

| Metric | Value |
|--------|-------|
| Files changed | 327 |
| Lines inserted | +4,661 |
| Lines deleted | -4,369 |
| Dead code removed | ~44 files |
| Re-export shim files removed | ~70 |
| Generated mock files removed | 57 |
| Total commits | 11 |
| Features created | 6 |
| Use cases implemented | 17 |
| Dependency boundary violations | 0 |

---

## Quality Assurance

| Check | Result |
|-------|--------|
| `fvm dart analyze` | 0 issues |
| `fvm dart format . --line-length=120` | 0 changes |
| `fvm dart fix --apply` | Nothing to fix |
| `fvm flutter test` | 472 passed, 0 failed |
| shared/ -> features/ imports | 0 violations |
| core/ -> shared/features/ imports | 0 violations |

---

## How to Test

```bash
# Clean build
fvm flutter clean && fvm flutter pub get

# Static analysis
fvm dart analyze

# Run all tests
fvm flutter test

# Run with coverage
fvm flutter test --coverage

# Run locally
fvm flutter run --target lib/main/main_local.dart

# Build
fvm flutter build apk --release --target lib/main/main_prod.dart
fvm flutter build web --target lib/main/main_prod.dart
```

---

## Commits

| Hash | Type | Description |
|------|------|-------------|
| `1f60adc` | refactor | BREAKING_CHANGE - migrate from layered to feature-first clean boundaries |
| `5930c4f` | bump | Version to 0.19.0 |
| `01d2a02` | refactor | Update imports for user_form_fields and editor_form_mode to shared/widgets |
| `ed084f7` | test | Fix tests and update dependencies and regenerate mocks |
| `a337b10` | test | Fix add BLoC import to register screen router test |
| `948b703` | docs | Update README to reflect feature-first clean architecture |
| `66632ce` | docs | Regenerate the high-level architecture diagram |
| `aed8780` | docs | Update CLAUDE.md with new architecture |
| `09b4ea8` | refactor | Test mockito to mocktail migration |
| `b6a26e9` | bump | Version to 0.19.1 |
| `4cfbc7d` | refactor | Test folder structure refactored to feature-first arch |

---

## Documentation

- [Architecture Migration Guide (TR)](architecture-migration.md)
- [Architecture Migration Guide (EN)](architecture-migration_en.md)
- [Feature-First Clean Boundaries](feature-first-clean-boundaries.md)
- [High-Level Architecture Diagram](high-level-architecture.svg)
