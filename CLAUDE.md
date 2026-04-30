# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter BLoC Advance Template - a production-ready Flutter application using BLoC pattern for state management. Supports Android, iOS, Web, macOS, Linux, and Windows.

- **Flutter:** 3.41.8 | **Dart SDK:** ^3.11.1 | **FVM** is used for Flutter version management
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

This project follows a **Feature-First Clean Architecture**. Every development MUST follow this modular approach.

### Project Structure

```
lib/
├── app/                    # Application foundation
│   ├── router/             # Centralized routing configuration
│   └── configuration/      # Global environment setup, logging, storage
├── features/               # Modular business features
│   └── <feature_name>/
│       ├── application/    # BLoCs & Use Cases (Business Logic)
│       ├── data/           # Repositories & Models (Data Layer)
│       ├── navigation/     # Feature-specific route definitions
│       └── presentation/   # Pages & Widgets (UI Layer)
├── shared/                 # Shared foundation across features
│   ├── design_system/      # Theme, typography, color tokens, atoms
│   ├── models/             # Cross-feature models/entities (e.g., UserEntity)
│   ├── utils/              # Generic utility functions
│   └── widgets/            # Reusable components (buttons, forms, etc.)
├── generated/              # Auto-generated localization (do not edit)
├── l10n/                   # ARB translation files
└── main/                   # Entry points (main_local.dart, main_prod.dart)
```

### Developing a Feature

- **Strict Isolation:** Features should not import from other features' internal directories (e.g., `features/user/presentation`).
- **Shared Access:** Cross-feature logic or models MUST be moved to `shared/`.
- **Clean Boundaries:** Each feature module is self-contained. Use Case (Application) layer should only depend on Repository (Data) interfaces.

## BLoC Pattern

Every feature follows: **Event → BLoC → State → UI**
- BLoCs use `Equatable` for state equality, `copyWith()` for immutable updates.
- States use status enums: `initial`, `loading`, `success`, `failure`.
- Local UI state can be handled within the page, but business logic MUST be in BLoCs.

## Environments

- **dev/test** → mock data from `assets/mock/*.json`
- **prod** → real API (configured in `lib/app/configuration/environment.dart`)

## Adding a New Feature

1. Create a new directory under `lib/features/<feature_name>/`.
2. Define models and repository implementations in `data/`.
3. Add Use Cases and BLoCs in `application/`.
4. Define feature-specific routes in `navigation/`.
5. Implement pages and feature-specific widgets in `presentation/`.
6. Register the feature routes in `lib/app/router/app_router.dart`.
7. Add translations to `lib/l10n/` and run `fvm dart run intl_utils:generate`.
8. Write tests mirroring the feature structure under `test/features/<feature_name>/`.
