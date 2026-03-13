# Advanced Flutter BLoC Template

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Flutter](https://img.shields.io/badge/Flutter-3.41.4-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11.1-0175C2?logo=dart)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Linux%20%7C%20Windows-2E7D32)
![Open Source](https://img.shields.io/badge/Open%20Source-Community%20Template-black)

A production-ready, community-friendly Flutter starter built with BLoC, repository pattern, responsive UI, role-based access control, internationalization, and multi-environment support. It is designed to help you move from prototype to maintainable product faster across mobile, web, and desktop.

**Useful links:** [Wiki](https://deepwiki.com/cevheri/flutter-bloc-advanced) · [Upgrade Guide](docs/upgrade_flutter_3.41.4.md) · [Transformation Log](docs/clean-modernize-strengthen.md) · [Report an Issue](https://github.com/cevheri/flutter-bloc-advanced/issues) · [Contributing](#contributing)

## Why This Template?

- Production-oriented structure with clear separation between presentation, business logic, and data access.
- Ready-to-use authentication, role-based routing, user management, localization, theming, and dashboard flows.
- Local mock mode for rapid development and production mode for real API integration.
- Works as an open-source base project for teams, side projects, internal products, and community contributions.

## Screenshots

The screenshots below are included to help contributors and adopters understand the current UX quickly before cloning or running the project.

### Web Experience

| Dark Login | Light Login |
| --- | --- |
| ![Web login screen in dark theme](docs/screenshots/web-login-dark.png) | ![Web login screen in light theme](docs/screenshots/web-login-light.png) |

![Web user management list screen](docs/screenshots/web-list-user.png)

### Mobile Experience

| Login | Edit User |
| --- | --- |
| ![Mobile login screen](docs/screenshots/mobile-login.png) | ![Mobile edit user screen](docs/screenshots/mobile-edit-user.png) |

## What You Get Out of the Box

### Authentication

- Login with username and password
- Registration flow
- Forgot password flow
- OTP send and verify flow

### User Management

- Create, update, delete, and list users
- Account profile view and update
- Change password screen

### Access Control

- Role-based routing for Admin and User roles
- Public and private route separation
- Protected admin-only pages

### UI and Developer Experience

- Dark and light themes
- Responsive layout support
- English and Turkish localization
- Design system foundation with reusable components
- Multi-platform support for Android, iOS, Web, macOS, Linux, and Windows

### Architecture

- BLoC for state management
- Feature-First Clean Architecture with domain layer (entities + repository interfaces)
- Use Cases for business logic isolation
- Repository pattern with `Result<T>` sealed type (no raw exceptions)
- Typed error hierarchy (`NetworkError`, `AuthError`, `ValidationError`, `ServerError`, etc.)
- Dio HTTP client with interceptor chain (auth, logging, mock)
- Feature-based routing with clean boundaries
- Manual JSON serialization for models
- Environment-driven configuration for local and production modes
- Architecture guard tests enforcing dependency rules

![High-level architecture diagram](docs/high-level-architecture.svg)

## Quick Start

### Prerequisites

- Flutter `3.41.4` and Dart `3.11.1`
- [FVM](https://fvm.app/documentation/getting-started/installation) recommended for version consistency
- Android SDK for Android builds
- Xcode for iOS and macOS builds

### Install FVM

```shell
# macOS / Linux
brew tap leoafarias/fvm
brew install fvm

# Windows
choco install fvm
```

### Setup

```shell
git clone https://github.com/cevheri/flutter-bloc-advanced.git
cd flutter-bloc-advanced

fvm install 3.41.4
fvm use 3.41.4
fvm flutter pub get
```

### Run Locally With Mock Data

All local requests use `assets/mock/`, so you can explore the app without standing up a backend first.

```shell
# Mobile
fvm flutter run --target lib/main/main_local.dart

# Web
fvm flutter run -d chrome --target lib/main/main_local.dart

# Web with a specific port
fvm flutter run -d chrome --web-port 3000 --target lib/main/main_local.dart
```

### Demo Credentials

| Role | Username | Password | Access |
| --- | --- | --- | --- |
| Admin | `admin` | `admin` | All pages |
| User | `user` | `user` | Own profile and settings |

### Run Against the Real API

```shell
# Mobile
fvm flutter run --target lib/main/main_prod.dart

# Web
fvm flutter run -d chrome --target lib/main/main_prod.dart
```

The production environment is configured in `lib/infrastructure/config/environment.dart`.

## Tech Stack

| Category | Technology |
| --- | --- |
| Flutter | 3.41.4 |
| Dart | 3.11.1 |
| State Management | flutter_bloc 9.1.1 |
| Routing | go_router 17.1.0 |
| HTTP | dio 5.7.0 (interceptor chain: auth, logging, mock) |
| Forms | flutter_form_builder 10.3.0+2 |
| Localization | intl 0.20.2, intl_utils 2.8.14 |
| Storage | shared_preferences 2.5.4 |
| Charts | fl_chart 1.1.1 |
| Testing | flutter_test, bloc_test, mocktail |

## Project Structure

```text
lib/
  app/                 # Application foundation
    di/                # Dependency injection (manual, no get_it)
    router/            # Centralized routing with go_router
    shell/             # Responsive shell (sidebar, top bar, bottom nav, command palette)
    theme/             # Theme management
  core/                # Zero-dependency foundation
    errors/            # AppError sealed hierarchy + API exceptions
    result/            # Result<T> sealed type (Success / Failure)
    logging/           # Structured logging (AppLogger)
    security/          # JWT utilities
  features/            # Feature-based clean architecture modules
    <feature>/
      application/     # BLoCs, Use Cases
      data/            # Models, Repositories (concrete implementations)
      domain/          # Entities, Repository interfaces
      navigation/      # Feature-specific routes
      presentation/    # Pages and feature-specific widgets
  infrastructure/      # Cross-cutting technical concerns
    config/            # Environment, TemplateConfig
    http/              # Dio ApiClient + interceptors (auth, logging, mock)
    storage/           # Local storage (SharedPreferences)
  shared/              # Shared foundation across features
    design_system/     # Theme, typography, color tokens, 16 components
    models/            # Cross-feature entities (UserEntity, PagedResult)
    widgets/           # Reusable components (buttons, forms, dialogs)
  generated/           # Localization generated files (do not edit)
  l10n/                # ARB translation files
  main/                # Entry points (main_local.dart, main_prod.dart)

test/                  # Mirrors lib/ structure
  architecture/        # Import guard tests (dependency rule enforcement)
  features/            # Feature tests (application, data, presentation)
  mocks/               # Mock classes and fake data
```

## Customizing for Your Project

All template placeholders use `__KEYWORD__` naming. Run a **global search** for `__` across the project, replace each keyword with your own value, and you are done.

| Keyword | Description | Example | Where Used |
| --- | --- | --- | --- |
| `__APP_NAME__` | Full application name | `Acme Dashboard` | template_config.dart, manifest.json |
| `__APP_SHORT_NAME__` | Short name (PWA, mobile) | `Acme` | template_config.dart, manifest.json |
| `__APP_DESCRIPTION__` | One-line app description | `Team collaboration platform` | template_config.dart, manifest.json |
| `__PROD_API_URL__` | Production API endpoint | `https://api.acme.com/v1` | template_config.dart, index.html |
| `__WEB_BASE_URL__` | Deployment URL (trailing `/`) | `https://app.acme.com/` | template_config.dart, index.html, sitemap.xml |
| `__GITHUB_REPO_URL__` | GitHub repository URL | `https://github.com/acme/dashboard` | template_config.dart |
| `__AUTHOR_NAME__` | Developer or company name | `Acme Inc.` | template_config.dart, index.html, humans.txt |
| `__AUTHOR_EMAIL__` | Contact email | `dev@acme.com` | template_config.dart, CONTRIBUTING.md |
| `__AUTHOR_URL__` | Author website / profile | `https://github.com/acme` | template_config.dart, index.html, humans.txt |
| `__AUTHOR_LOCATION__` | Author location | `San Francisco, CA` | humans.txt |

Also update manually:

1. **`pubspec.yaml`** — Package name, version, description.
2. **`web/index.html`** — Page `<title>`, meta descriptions, Open Graph / Twitter Card text.
3. **`lib/l10n/intl_en.arb` / `intl_tr.arb`** — App-specific translations.

The central configuration file is `lib/infrastructure/config/template_config.dart` — Dart code throughout the app reads from this class.

## Build, Test, and Quality

### Build

```shell
# Android APK
fvm flutter build apk --target lib/main/main_prod.dart

# iOS
fvm flutter build ios --target lib/main/main_prod.dart

# Web
fvm flutter build web --target lib/main/main_prod.dart
```

### Test

```shell
# Run all tests
fvm flutter test

# With coverage
fvm flutter test --coverage

# Useful for debugging order-dependent issues
fvm flutter test --concurrency=1 --test-randomize-ordering-seed=random
```

### Analyze and Format

```shell
fvm dart analyze
fvm dart fix --apply
fvm dart format . --line-length=120
```

### Git Hooks (Optional)

Install pre-commit (format + analyze) and pre-push (test) hooks:

```shell
bash scripts/setup_hooks.sh
```

### Test Coverage Focus

| Layer | What is Tested |
| --- | --- |
| Use Cases | Business logic delegation, input routing |
| Models / Entities | `fromJson`, `toJson`, equality, `copyWith` |
| Mappers | Entity ↔ Model transformations |
| Repositories | API calls, Result type returns, error mapping |
| BLoCs | State transitions, event handling, error states |
| Screens | Widget rendering, user interactions, navigation |
| Architecture | Import guard tests enforcing dependency rules |

## CI/CD

GitHub Actions workflows included in this repository:

- `build_and_test.yml` for build and test automation
- `build-web.yml` for web builds
- `sonar_scanner.yml` for SonarQube analysis

To enable SonarQube, add the `SONAR_TOKEN` secret to your repository or organization.

## Android Tooling

| Component | Version |
| --- | --- |
| Gradle | 8.14 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.2.20 |
| Java Compatibility | 17 |
| NDK | Dynamic (`flutter.ndkVersion`) |
| Build Config | Kotlin DSL (`.gradle.kts`) |

## Adding a New Feature

1. Create a new feature folder under `lib/features/<feature>/`.
2. Define domain entities in `domain/entities/` and repository interface in `domain/repositories/`.
3. Implement data models in `data/models/` and repository in `data/repositories/` (return `Result<T>`).
4. Add use cases in `application/usecases/` (one class per operation).
5. Create BLoC(s) in `application/` using `switch (result) { case Success: ... case Failure: ... }`.
6. Implement the UI in `presentation/pages/`.
7. Define feature routes in `navigation/`.
8. Register the feature routes in `lib/app/router/app_router.dart`.
9. Register DI in `lib/app/di/app_dependencies.dart` (repository) and `app_scope.dart` (BLoC).
10. Add tests in `test/features/<feature>/` mirroring the feature structure.

**Dependency rules** (enforced by architecture guard tests):
- `core/` imports nothing from the project
- `shared/` imports only from `core/`
- `features/` imports from `shared/`, `infrastructure/`, `core/` — never from other features
- `app/` can import from all layers

## Contributing

Community contributions are welcome. If you want to improve the template, add features, polish documentation, or refine the UI, feel free to open an issue or submit a pull request.

1. Fork the repository.
2. Create a feature branch from your fork.
3. Make your changes with tests or documentation updates when relevant.
4. Run `fvm dart analyze` and `fvm flutter test`.
5. Open a pull request with a clear summary of the change.

If you are unsure where to start, documentation improvements, screenshot refreshes, and test coverage enhancements are all valuable contributions.

## Documentation

| Document | Description |
| --- | --- |
| [Transformation Log](docs/clean-modernize-strengthen.md) | What changed, why, before/after comparison |
| [Architecture Migration](docs/architecture-migration_en.md) | Feature-first migration guide |
| [Feature-First Boundaries](docs/feature-first-clean-boundaries.md) | Clean architecture design document |
| [Upgrade Guide](docs/upgrade_flutter_3.41.4.md) | Flutter 3.41.4 upgrade notes |

## References

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/cevheri/flutter-bloc-advanced)

- [Understanding Flutter BLoC: A Comprehensive Guide](https://cevheri.medium.com/understanding-flutter-bloc-a-comprehensive-guide-7100dabe3975)
- [Flutter Documentation](https://flutter.dev/)
- [BLoC Library](https://bloclibrary.dev/)
- [flutter_bloc on pub.dev](https://pub.dev/packages/flutter_bloc)
- [go_router on pub.dev](https://pub.dev/packages/go_router)
- [dio on pub.dev](https://pub.dev/packages/dio)

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
