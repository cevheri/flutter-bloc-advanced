# Architecture Migration Documentation

**Layered Architecture → Feature-First Clean Boundaries**

This document describes in detail the migration process from layered architecture to feature-first clean boundaries architecture.

---

## 1. Why Migrate?

### Problems with the Old Architecture

- **Horizontal dependencies:** All BLoCs were grouped under `presentation/common_blocs/`, all models under `data/models/`, causing unrelated files to sit side by side. Understanding a feature required searching across the entire project.
- **Unclear boundaries:** The relationship between `data/repository/login_repository.dart` and `presentation/screen/login/bloc/login_bloc.dart` was only visible through imports. There were no enforced architectural boundaries.
- **Poor scalability:** Adding a new feature required creating files in 5+ different directories.
- **Difficult test isolation:** Testing a feature independently was nearly impossible because dependencies were scattered across layers.
- **Dead code accumulation:** Unused City, District, and Customer modules had accumulated unnoticed.

### Benefits of the New Architecture

- **Feature isolation:** Each feature contains its own data, domain, application, presentation, and navigation layers.
- **Explicit dependency direction:** Unidirectional dependency flow: `core` ← `infrastructure` ← `shared` ← `features` ← `app`.
- **Easy onboarding:** A new developer can understand the full context by looking at only the relevant feature directory.
- **Independent testing:** Each feature can be tested in isolation through its own use cases and repository interfaces.

---

## 2. Old Architecture (Layered Architecture)

```
lib/
├── configuration/              # Environment, logging, storage, constants
│   ├── environment.dart
│   ├── app_logger.dart
│   ├── local_storage.dart
│   ├── app_key_constants.dart
│   ├── constants.dart
│   └── allowed_paths.dart
│
├── data/
│   ├── models/                 # All data models in one place
│   │   ├── user.dart
│   │   ├── jwt_token.dart
│   │   ├── menu.dart
│   │   ├── authority.dart
│   │   ├── dashboard_model.dart
│   │   ├── change_password.dart
│   │   ├── city.dart           # (dead code)
│   │   ├── district.dart       # (dead code)
│   │   ├── customer.dart       # (dead code)
│   │   └── ...
│   ├── repository/             # All repositories in one place
│   │   ├── login_repository.dart
│   │   ├── account_repository.dart
│   │   ├── user_repository.dart
│   │   ├── authority_repository.dart
│   │   ├── dashboard_repository.dart
│   │   ├── menu_repository.dart
│   │   ├── city_repository.dart    # (dead code)
│   │   ├── district_repository.dart # (dead code)
│   │   └── customer_repository.dart # (dead code)
│   ├── http_utils.dart
│   └── app_api_exception.dart
│
├── presentation/
│   ├── common_blocs/           # Global BLoCs
│   │   ├── account/
│   │   ├── authority/
│   │   ├── theme/
│   │   ├── sidebar/
│   │   ├── city/               # (dead code)
│   │   └── district/           # (dead code)
│   ├── common_widgets/         # Shared widgets
│   │   ├── drawer/
│   │   ├── language_notifier.dart
│   │   ├── top_actions_widget.dart
│   │   └── web_back_button_disabler.dart
│   ├── design_system/          # Theme, tokens, components
│   │   ├── theme/
│   │   ├── tokens/
│   │   └── components/
│   ├── screen/                 # Feature screens
│   │   ├── login/bloc/ + login_screen.dart
│   │   ├── register/bloc/ + register_screen.dart
│   │   ├── forgot_password/bloc/ + forgot_password_screen.dart
│   │   ├── change_password/bloc/ + change_password_screen.dart
│   │   ├── account/account_screen.dart
│   │   ├── dashboard/bloc/ + dashboard_page.dart
│   │   ├── user/bloc/ + editor/ + list/
│   │   ├── settings/bloc/ + settings_screen.dart
│   │   ├── catalog/catalog_screen.dart
│   │   ├── home/               # (dead code)
│   │   ├── customer/           # (dead code)
│   │   └── components/         # Shared form widgets
│   └── shell/                  # App shell (sidebar, top bar, bottom nav)
│
├── routes/
│   ├── app_routes_constants.dart
│   ├── app_router.dart
│   └── go_router_routes/
│       ├── app_go_router_config.dart
│       └── routes/
│
└── utils/
    ├── security_utils.dart
    ├── icon_utils.dart
    ├── app_constants.dart
    ├── menu_list_cache.dart
    ├── message.dart            # (dead code)
    └── storage.dart            # (dead code)
```

### File Distribution in Old Architecture

| Directory | Responsibility |
|-----------|---------------|
| `configuration/` | Environment, logging, storage |
| `data/models/` | All data models (no feature distinction) |
| `data/repository/` | All repository implementations |
| `presentation/common_blocs/` | Application-wide BLoCs |
| `presentation/screen/<feature>/` | Feature-specific BLoC + UI |
| `presentation/design_system/` | Theme and UI tokens |
| `routes/` | Router configuration |
| `utils/` | Utility functions |

---

## 3. New Architecture (Feature-First Clean Boundaries)

```
lib/
├── app/                        # Composition root (35 files)
│   ├── bootstrap/              # Application startup
│   │   ├── app_bootstrap.dart
│   │   ├── app_bootstrap_config.dart
│   │   └── app_session_listeners.dart
│   ├── di/                     # Dependency injection
│   │   ├── app_dependencies.dart
│   │   └── app_scope.dart
│   ├── localization/
│   │   └── language_notifier.dart
│   ├── router/                 # Router composition
│   │   ├── app_router.dart             # AppRouterFactory
│   │   ├── app_router_strategy.dart    # AppRouter strategy pattern
│   │   ├── app_router_refresh_notifier.dart
│   │   ├── app_go_router_config.dart
│   │   └── app_routes_constants.dart
│   ├── session/
│   │   └── session_cubit.dart
│   ├── shell/                  # App shell components
│   │   ├── app_shell.dart
│   │   ├── responsive_scaffold.dart
│   │   ├── content_area.dart
│   │   ├── sidebar/            # Sidebar widget + BLoC
│   │   ├── top_bar/            # Top bar + breadcrumb
│   │   ├── bottom_nav/         # Bottom navigation
│   │   ├── command_palette/    # Ctrl+K command palette
│   │   ├── drawer/             # Drawer BLoC
│   │   ├── models/menu.dart
│   │   ├── repositories/menu_repository.dart
│   │   └── menu_list_cache.dart
│   ├── theme/                  # Theme BLoC
│   └── app.dart
│
├── core/                       # Cross-cutting primitives (5 files)
│   ├── errors/
│   │   └── app_api_exception.dart
│   ├── logging/
│   │   └── app_logger.dart
│   ├── security/
│   │   ├── allowed_paths.dart
│   │   └── security_utils.dart
│   └── testing/
│       └── app_key_constants.dart
│
├── features/                   # Business capabilities (93 files)
│   ├── account/    (14 files)
│   │   ├── application/        # AccountBloc + use cases
│   │   ├── data/models/        # ChangePassword
│   │   ├── data/repositories/  # AccountRepository impl
│   │   ├── domain/repositories/ # IAccountRepository
│   │   ├── navigation/         # AccountFeatureRoutes
│   │   └── presentation/pages/ # AccountPage
│   │
│   ├── auth/       (30 files)
│   │   ├── application/        # LoginBloc, RegisterBloc, ForgotPasswordBloc, ChangePasswordBloc + use cases
│   │   ├── data/models/        # JWTToken, UserJwt, SendOtpRequest, VerifyOtpRequest
│   │   ├── data/mappers/       # AuthMapper
│   │   ├── data/repositories/  # LoginRepository (AuthRepositoryImpl)
│   │   ├── domain/entities/    # AuthEntity
│   │   ├── domain/repositories/ # IAuthRepository
│   │   ├── navigation/         # AuthFeatureRoutes
│   │   └── presentation/pages/ # LoginPage, RegisterPage, ForgotPasswordPage, ChangePasswordPage
│   │
│   ├── catalog/    (3 files)
│   │   ├── navigation/         # CatalogFeatureRoutes
│   │   └── presentation/pages/ # CatalogScreen
│   │
│   ├── dashboard/  (12 files)
│   │   ├── application/        # DashboardCubit + use cases
│   │   ├── data/models/        # DashboardModel
│   │   ├── data/mappers/       # DashboardMapper
│   │   ├── data/repositories/  # DashboardMockRepository
│   │   ├── domain/entities/    # DashboardEntity
│   │   ├── domain/repositories/ # IDashboardRepository
│   │   ├── navigation/         # DashboardFeatureRoutes
│   │   └── presentation/pages/ # DashboardPage, DashboardHomePage
│   │
│   ├── settings/   (10 files)
│   │   ├── application/        # SettingsBloc + use cases
│   │   ├── navigation/         # SettingsFeatureRoutes
│   │   └── presentation/pages/ # SettingsPage, SettingsScreen
│   │
│   └── users/      (24 files)
│       ├── application/        # UserBloc, AuthorityBloc + use cases
│       ├── data/models/        # User, Authority, UserModel
│       ├── data/mappers/       # UserMapper
│       ├── data/repositories/  # UserRepository, AuthorityRepository
│       ├── domain/repositories/ # IUserRepository
│       ├── navigation/         # UsersFeatureRoutes
│       └── presentation/       # UserListPage, UserEditorPage + widgets
│
├── infrastructure/             # External adapters (4 files)
│   ├── config/
│   │   ├── environment.dart
│   │   └── constants.dart
│   ├── http/
│   │   └── http_utils.dart
│   └── storage/
│       └── local_storage.dart
│
├── shared/                     # Business-free reusable UI (40 files)
│   ├── design_system/
│   │   ├── components/         # 14 composable components (AppButton, AppCard, ...)
│   │   ├── theme/              # AppTheme, SemanticColors, ThemeColors
│   │   └── tokens/             # Spacing, breakpoints, durations, sizes, ...
│   ├── models/
│   │   └── user_entity.dart
│   ├── utils/
│   │   ├── app_constants.dart
│   │   └── icon_utils.dart
│   └── widgets/                # Shared widgets
│       ├── confirmation_dialog_widget.dart
│       ├── responsive_form_widget.dart
│       ├── submit_button_widget.dart
│       ├── theme_selection_dialog.dart
│       ├── language_selection_dialog.dart
│       ├── editor_form_mode.dart
│       ├── user_form_fields.dart
│       ├── web_back_button_disabler.dart
│       └── widgets.dart
│
├── generated/                  # Auto-generated localization (untouched)
├── l10n/                       # ARB files (untouched)
└── main/                       # Entry points (untouched)
    ├── app.dart
    ├── main_local.dart
    └── main_prod.dart
```

### File Distribution in New Architecture

| Directory | File Count | Responsibility |
|-----------|-----------|---------------|
| `app/` | 35 | Composition root, DI, router, shell, theme, session |
| `core/` | 5 | Errors, logging, security, test constants |
| `features/` | 93 | 6 feature modules (account, auth, catalog, dashboard, settings, users) |
| `infrastructure/` | 4 | HTTP, environment, storage |
| `shared/` | 40 | Design system, shared widgets and utilities |
| `main/` | 5 | Entry points |
| **Total** | **182** | |

---

## 4. Dependency Rules

```
app  ────→  features, shared, infrastructure, core
features ──→  shared, infrastructure, core
shared  ───→  core
infrastructure → core

Forbidden directions:
  shared  ──✗──→  features
  core    ──✗──→  shared, features
  feature_a ─✗──→  feature_b/presentation or feature_b/data
```

These rules have been verified after the migration:
- `lib/shared/` has **no** imports from `features/`
- `lib/core/` has **no** imports from `shared/` or `features/`

---

## 5. Feature Structure

Each feature follows this standard structure:

```
features/<feature>/
├── application/          # BLoC/Cubit + use case orchestration
│   ├── <feature>_bloc.dart
│   ├── <feature>_event.dart
│   ├── <feature>_state.dart
│   └── usecases/
│       └── <action>_usecase.dart
├── data/
│   ├── models/           # Data models (fromJson/toJson)
│   ├── mappers/          # Entity ↔ Model conversions
│   └── repositories/     # Repository implementations
├── domain/
│   ├── entities/         # Domain entities (Flutter-free)
│   └── repositories/     # Repository interfaces (abstract class)
├── navigation/           # Feature route definitions
│   └── <feature>_routes.dart
└── presentation/
    ├── pages/            # Screens
    └── widgets/          # Feature-local widgets
```

### Use Case Pattern

BLoCs no longer depend directly on repositories; they work through use cases:

```dart
// Old: BLoC → Repository
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository repository;
  LoginBloc({required this.repository});
}

// New: BLoC → UseCase → Repository Interface
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required AuthenticateUserUseCase authenticateUserUseCase,
    required SendOtpUseCase sendOtpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required GetAccountUseCase getAccountUseCase,
  });
}
```

---

## 6. Migration Steps

### Step 1: Dead Code Cleanup

Unused modules were completely removed:

| Removed Module | File Count | Reason |
|---------------|-----------|--------|
| City BLoC + Model + Repository | 6 | Not used anywhere |
| District BLoC + Model + Repository | 6 | Not used anywhere |
| Customer Screen + BLoC + Model + Repository | 11 | Empty BLoC, screens unused |
| Home Screen | 1 | 0 imports |
| `utils/message.dart` | 1 | 0 imports |
| `utils/storage.dart` | 1 | Entirely commented-out code |
| `top_actions_widget.dart` | 1 | 0 imports, dead code |
| `drawer_widget.dart` | 1 | 0 imports, dead code |
| Mock JSON files | 5 | Belonged to removed modules |
| Related test files | 11 | Belonged to removed modules |
| **Total** | **~44** | |

### Step 2: Design System Consolidation

27 files moved from `presentation/design_system/` → `shared/design_system/`:

- **Components:** 14 composable components + barrel export
- **Theme:** AppTheme, AppThemePalette, SemanticColors, ThemeColors
- **Tokens:** AppSpacing, AppBreakpoints, AppDurations, AppSizes, AppRadius, AppElevation, AppTypography

All imports (~30 files) were updated directly; the old directory was completely removed.

### Step 3: LoginBloc and Auth Repository Migration

- `LoginBloc` constructor converted to use case-based DI (use cases instead of direct repository injection)
- `LoginRepository` → `features/auth/data/repositories/auth_repository_impl.dart`
- Auth models (JWTToken, UserJwt, SendOtpRequest, VerifyOtpRequest) → `features/auth/data/models/`

### Step 4: Remaining Data Layer Migration

| Source | Target |
|--------|--------|
| `data/models/menu.dart` | `app/shell/models/menu.dart` |
| `data/repository/menu_repository.dart` | `app/shell/repositories/menu_repository.dart` |
| `utils/menu_list_cache.dart` | `app/shell/menu_list_cache.dart` |
| `data/models/dashboard_model.dart` | `features/dashboard/data/models/` |
| `data/repository/dashboard_repository.dart` | `features/dashboard/data/repositories/` |
| `data/models/authority.dart` | `features/users/data/models/` |
| `data/repository/authority_repository.dart` | `features/users/data/repositories/` |
| `data/http_utils.dart` | `infrastructure/http/http_utils.dart` |
| `data/app_api_exception.dart` | `core/errors/app_api_exception.dart` |
| `data/models/change_password.dart` | `features/account/data/models/` |
| `data/models/user.dart` | `features/users/data/models/` |

### Step 5: Cross-Feature Import Fixes

`user_form_fields.dart` and `editor_form_mode.dart` under `features/users/presentation/widgets/` were used by multiple features, so they were moved to `shared/widgets/`. This keeps feature boundaries clean.

### Step 6: Configuration and Utils Migration

| Source | Target |
|--------|--------|
| `configuration/environment.dart` | `infrastructure/config/environment.dart` |
| `configuration/local_storage.dart` | `infrastructure/storage/local_storage.dart` |
| `configuration/app_logger.dart` | `core/logging/app_logger.dart` |
| `configuration/app_key_constants.dart` | `core/testing/app_key_constants.dart` |
| `configuration/constants.dart` | `infrastructure/config/constants.dart` |
| `configuration/allowed_paths.dart` | `core/security/allowed_paths.dart` |
| `utils/security_utils.dart` | `core/security/security_utils.dart` |
| `utils/icon_utils.dart` | `shared/utils/icon_utils.dart` |
| `utils/app_constants.dart` | `shared/utils/app_constants.dart` |

### Step 7: Shell, Router, and Shim Cleanup

**Shell components:** All widgets under `presentation/shell/` (sidebar, top bar, breadcrumb, bottom nav, command palette, content area) were moved to `app/shell/`.

**Router consolidation:** The `routes/` directory was integrated into `app/router/`:
- `app_routes_constants.dart` → `app/router/app_routes_constants.dart`
- `app_router.dart` (strategy pattern) → `app/router/app_router_strategy.dart`
- `app_go_router_config.dart` → `app/router/app_go_router_config.dart`
- Feature-specific route files were already under `features/*/navigation/`

**Reverse shim fixes:** ForgotPasswordBloc, RegisterBloc, ChangePasswordBloc, and DashboardCubit implementations were moved from their old locations to `features/`.

**Shim cleanup:** All re-export shim files (~70 total) were deleted and old directories were removed. Test file imports were also updated to canonical paths.

---

## 7. Removed Old Directories

After the migration was completed, the following directories were entirely removed:

| Directory | Description |
|-----------|-------------|
| `lib/presentation/` | Everything moved to `features/`, `app/`, `shared/` |
| `lib/data/` | Models and repositories moved to their respective features |
| `lib/configuration/` | Distributed to `infrastructure/` and `core/` |
| `lib/utils/` | Distributed to `shared/utils/` and `core/security/` |
| `lib/routes/` | Integrated into `app/router/` |

---

## 8. Migration Strategy: Re-Export Shim Pattern

An **incremental migration** strategy was applied throughout the transition:

1. The implementation was copied to its new location (with imports updated to canonical paths)
2. The old file was converted to a re-export shim: `export 'new_location.dart';`
3. All existing imports continued to work through the shim
4. After all imports were updated to canonical paths, the shim files were deleted

This strategy enabled zero-downtime migration in a large codebase. Validation was performed after each step using `dart analyze` and `flutter test`.

---

## 9. Validation Results

| Check | Result |
|-------|--------|
| `fvm dart analyze` | 0 issues |
| `fvm flutter test` | +407 -9 (9 failures pre-existing from mock type mismatches) |
| `shared/` → `features/` import check | 0 violations |
| `core/` → `shared/` or `features/` import check | 0 violations |

---

## 10. Before / After Comparison

### Directory Structure

| Before | After |
|--------|-------|
| `lib/configuration/` (6 files) | `lib/core/` (5 files) + `lib/infrastructure/` (4 files) |
| `lib/data/` (models + repos, ~20 files) | Each feature owns its own `data/` directory |
| `lib/presentation/common_blocs/` (8+ blocs) | `lib/app/theme/` + `lib/app/shell/` + `lib/features/*/application/` |
| `lib/presentation/screen/` (all feature UIs) | `lib/features/*/presentation/pages/` |
| `lib/presentation/design_system/` (27 files) | `lib/shared/design_system/` (27 files) |
| `lib/presentation/shell/` (8 widgets) | `lib/app/shell/` (full shell ecosystem) |
| `lib/routes/` (9 files) | `lib/app/router/` (5 files) + `lib/features/*/navigation/` |
| `lib/utils/` (6 files) | `lib/shared/utils/` + `lib/core/security/` |

### BLoC Structure

| Before | After |
|--------|-------|
| `presentation/common_blocs/account/` | `features/account/application/account_bloc.dart` |
| `presentation/common_blocs/authority/` | `features/users/application/authority_bloc.dart` |
| `presentation/common_blocs/theme/` | `app/theme/theme_bloc.dart` |
| `presentation/common_blocs/sidebar/` | `app/shell/sidebar/sidebar_bloc.dart` |
| `presentation/screen/login/bloc/` | `features/auth/application/login_bloc.dart` |
| `presentation/screen/register/bloc/` | `features/auth/application/register_bloc.dart` |
| `presentation/screen/dashboard/bloc/` | `features/dashboard/application/dashboard_cubit.dart` |
| `presentation/screen/user/bloc/` | `features/users/application/user_bloc.dart` |
| `presentation/screen/settings/bloc/` | `features/settings/application/settings_bloc.dart` |

### Repository Structure

| Before | After |
|--------|-------|
| `data/repository/login_repository.dart` | `features/auth/data/repositories/auth_repository_impl.dart` |
| `data/repository/account_repository.dart` | `features/account/data/repositories/account_repository.dart` |
| `data/repository/user_repository.dart` | `features/users/data/repositories/user_repository.dart` |
| `data/repository/authority_repository.dart` | `features/users/data/repositories/authority_repository.dart` |
| `data/repository/dashboard_repository.dart` | `features/dashboard/data/repositories/dashboard_mock_repository.dart` |
| `data/repository/menu_repository.dart` | `app/shell/repositories/menu_repository.dart` |

---

## 11. Adding a New Feature Guide

To add a new feature:

```bash
# 1. Create the feature directory structure
mkdir -p lib/features/<feature>/{application/usecases,data/{models,mappers,repositories},domain/{entities,repositories},navigation,presentation/{pages,widgets}}

# 2. Domain layer (entity + repository interface)
# lib/features/<feature>/domain/entities/<feature>_entity.dart
# lib/features/<feature>/domain/repositories/<feature>_repository.dart

# 3. Data layer (model + mapper + repository impl)
# lib/features/<feature>/data/models/<feature>_model.dart
# lib/features/<feature>/data/mappers/<feature>_mapper.dart
# lib/features/<feature>/data/repositories/<feature>_repository_impl.dart

# 4. Application layer (use case + BLoC)
# lib/features/<feature>/application/usecases/<action>_usecase.dart
# lib/features/<feature>/application/<feature>_bloc.dart

# 5. Presentation layer
# lib/features/<feature>/presentation/pages/<feature>_page.dart

# 6. Navigation
# lib/features/<feature>/navigation/<feature>_routes.dart

# 7. DI registration: lib/app/di/app_dependencies.dart and app_scope.dart
# 8. Router integration: lib/app/router/app_router.dart
# 9. Route constant: lib/app/router/app_routes_constants.dart
# 10. Tests: test/features/<feature>/
```

---

## 12. References

- [Feature-First Clean Boundaries Design Document](feature-first-clean-boundaries.md)
- [Flutter BLoC Library](https://bloclibrary.dev/)
- [go_router Package](https://pub.dev/packages/go_router)
