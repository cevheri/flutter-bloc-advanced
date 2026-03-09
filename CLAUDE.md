# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter BLoC Advance Template - a production-ready Flutter application using BLoC pattern for state management. Supports Android, iOS, Web, macOS, Linux, and Windows.

- **Flutter:** 3.41.4 | **Dart SDK:** ^3.11.1 | **FVM** is used for Flutter version management
- **Line width:** 120 characters (configured in `analysis_options.yaml`)

## Common Commands

```bash
# Dependencies
fvm flutter pub get

# Run locally (mock API)
fvm flutter run --target lib/main/main_local.dart

# Run production (real API)
fvm flutter run --target lib/main/main_prod.dart

# Analysis & formatting
fvm dart analyze
fvm dart fix --apply
fvm dart format . --line-length=120

# Tests
fvm flutter test
fvm flutter test test/path/to/specific_test.dart          # single test file
fvm flutter test --coverage                                # with coverage

# Localization code generation (after editing ARB files)
fvm dart run intl_utils:generate

# Build
fvm flutter build apk --release --target lib/main/main_prod.dart
fvm flutter build web --target lib/main/main_prod.dart
```

## Architecture

### Layered Structure

```
lib/
├── configuration/          # Environment, logging, local storage, app setup
├── data/
│   ├── models/             # Data models (manual fromJson/toJson, Equatable)
│   └── repository/         # Repository pattern - abstracts API/mock data access
├── generated/              # Auto-generated localization (do not edit)
├── l10n/                   # ARB translation files (en, tr)
├── main/                   # Entry points: main_local.dart (dev), main_prod.dart (prod)
├── presentation/
│   ├── common_blocs/       # Global BLoCs: Account, Authority, Theme, Drawer
│   ├── common_widgets/     # Shared widgets (drawer, language selector)
│   ├── design_system/      # Theme, typography, color tokens
│   └── screen/             # Feature screens, each with its own BLoC
├── routes/                 # go_router (primary), with legacy auto_route/GetX support
└── utils/                  # Utility functions
```

### BLoC Pattern

Every feature follows: **Event → BLoC → State → UI**

- BLoCs use `Equatable` for state equality, `copyWith()` for immutable updates
- States use status enums: `initial`, `loading`, `success`, `failure`
- Global BLoCs (Account, Authority, Theme, Drawer) are provided via `MultiBlocProvider` in `lib/main/app.dart`
- Feature BLoCs live in `lib/presentation/screen/<feature>/bloc/`

### Environments

Configured in `lib/configuration/environment.dart`:
- **dev/test** → mock data from `assets/mock/*.json`
- **prod** → real API at `https://dhw-api.onrender.com/api`

Entry points: `main_local.dart` sets `Environment.dev`, `main_prod.dart` sets `Environment.prod`.

### Routing

Primary router: **go_router** configured in `lib/routes/go_router_routes/`. Route constants in `lib/routes/app_routes_constants.dart`. Route guards check JWT token via `SecurityUtils`.

### Models

No code generation for models - all use manual `fromJson`/`toJson` factory methods and `Equatable`.

### Storage

Strategy pattern in `lib/configuration/local_storage.dart`: `AppLocalStorage` with `SharedPreferencesStrategy` or `GetStorageStrategy`. `AppLocalStorageCached` provides in-memory cache for frequently accessed values (jwtToken, roles, language, theme).

## Testing

Tests mirror the `lib/` structure under `test/`. Uses `bloc_test` for BLoC testing and `mockito` for mocks.

- `test/test_utils.dart` - shared `TestUtils` class; call `setupUnitTest()` in `setUp` and `tearDownUnitTest()` in `tearDown`
- `test/fake/` - fake data generators for tests
- BLoC tests use `blocTest()` from `bloc_test` package
- Tests run in `Environment.test` (mock data)

## Adding a New Feature

1. Create model in `lib/data/models/`
2. Create repository in `lib/data/repository/`
3. Add mock JSON in `assets/mock/` (for dev/test environments)
4. Create screen directory under `lib/presentation/screen/<feature>/` with `bloc/` subdirectory
5. Add BLoC (events, states, bloc) following existing patterns (e.g., `customer` or `user`)
6. Add route in `lib/routes/go_router_routes/` and register constant in `app_routes_constants.dart`
7. Add translations to `lib/l10n/intl_en.arb` and `intl_tr.arb`, then run `fvm dart run intl_utils:generate`
8. Write tests mirroring the same structure under `test/`
