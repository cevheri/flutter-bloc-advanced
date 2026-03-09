# Advanced Flutter BLoC Template

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[Wiki](https://deepwiki.com/cevheri/flutter-bloc-advanced)

---

A production-ready Flutter template built on BLoC architecture. Provides a solid foundation with authentication, role-based access control, user management, theming, internationalization, and multi-environment support (mock/API). Designed for scalable, maintainable applications targeting Android, iOS, Web, macOS, Linux, and Windows.

---

![img.png](assets/README_header.png)

---

## Tech Stack

| Category | Technology |
|---|---|
| **Flutter** | 3.41.4 (Dart 3.11.1) |
| **State Management** | flutter_bloc 9.1.1 |
| **Routing** | go_router 17.1.0 |
| **HTTP** | http 1.6.0 |
| **Theming** | adaptive_theme 3.7.2 |
| **Forms** | flutter_form_builder 10.3.0+2 |
| **Localization** | intl 0.20.2 + intl_utils |
| **Testing** | flutter_test, bloc_test 10.0.0, mockito 5.6.3 |

## Features

### Authentication
- Login (username/password)
- Register
- Forgot Password
- One Time Password (OTP) - Send and Verify

### User Management
- Create, Update, Delete, List users
- Account view and update
- Change password

### Access Control
- Role-based routing (Admin / User)
- Public and private routes
- Protected admin pages

### UI/UX
- Dark and light themes with adaptive_theme
- Poppins font family
- Responsive layout support
- Internationalization (English, Turkish)
- Dashboard with summary, activities, quick actions

### Architecture
- **BLoC Pattern** - Separation of data, business logic, and presentation
- **Repository Pattern** - Abstracted data access layer
- **Manual JSON Serialization** - No code generation required for models
- **Multi-environment** - Local (mock data) and Production (real API)
- **Multi-platform** - Android, iOS, Web, macOS, Linux, Windows

---

## Project Structure

```
lib/
  configuration/       # App config, environment, storage, logging
  data/
    models/            # Data models with manual fromJson/toJson
    repository/        # Repository implementations
  generated/           # Localization generated files
  l10n/                # Localization ARB files
  main/                # Entry points (main_local.dart, main_prod.dart)
  presentation/
    common_blocs/      # Shared BLoCs (account, authority)
    common_widgets/    # Reusable widgets (drawer, etc.)
    design_system/     # Design tokens and components
    screen/            # Feature screens with their BLoCs
  routes/              # Navigation (go_router, navigator, get)
  utils/               # Utility functions

test/
  conf/                # Test configuration
  data/model/          # Model unit tests
  data/repository/     # Repository unit tests
  presentation/blocs/  # BLoC unit tests
  presentation/screen/ # Screen widget tests
  presentation/widgets/# Widget unit tests
```

---

## Getting Started

### Prerequisites

- Flutter 3.41.4 (recommended via [FVM](https://fvm.app/documentation/getting-started/installation))
- Dart 3.11.1
- Android SDK (for Android builds)
- Xcode (for iOS/macOS builds)

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

---

## Running the App

### Local Environment (Mock Data)

All requests use mock data from `assets/mock/`. No backend required.

```shell
# Mobile
fvm flutter run --target lib/main/main_local.dart

# Web
fvm flutter run -d chrome --target lib/main/main_local.dart

# Web with specific port
fvm flutter run -d chrome --web-port 3000 --target lib/main/main_local.dart
```

**Login credentials:**

| Role | Username | Password | Access |
|------|----------|----------|--------|
| Admin | admin | admin | All pages |
| User | user | user | Own profile, settings |

### Production Environment (Real API)

Connects to configured API endpoint.

```shell
# Mobile
fvm flutter run --target lib/main/main_prod.dart

# Web
fvm flutter run -d chrome --target lib/main/main_prod.dart
```

---

## Building

```shell
# Android APK
fvm flutter build apk --target lib/main/main_prod.dart

# iOS
fvm flutter build ios --target lib/main/main_prod.dart

# Web
fvm flutter build web --target lib/main/main_prod.dart
```

---

## Testing

```shell
# Run all tests
fvm flutter test

# Run with single thread (useful for debugging)
fvm flutter test --concurrency=1 --test-randomize-ordering-seed=random
```

### Test Coverage

| Layer | What is Tested |
|-------|---------------|
| **Models** | fromJson, toJson, equality, edge cases |
| **Repositories** | API calls, error handling, mock responses |
| **BLoCs** | State transitions, event handling, error states |
| **Screens** | Widget rendering, user interactions, navigation |
| **Widgets** | Reusable component behavior |

---

## Code Quality

### Analyze

```shell
fvm dart analyze
```

### Fix

```shell
fvm dart fix --apply
```

### Format

```shell
fvm dart format . --line-length=120
```

### SonarQube

GitHub Actions integration is configured. Add `SONAR_TOKEN` secret to your repository.

---

## Android Configuration

| Component | Version |
|---|---|
| Gradle | 8.14 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.2.20 |
| Java Compatibility | 17 |
| NDK | Dynamic (flutter.ndkVersion) |
| Build Config | Kotlin DSL (.gradle.kts) |

---

## CI/CD

GitHub Actions workflows:

- **build_and_test.yml** - Build and test pipeline
- **build-web.yml** - Web build pipeline
- **sonar_scanner.yml** - SonarQube code quality analysis

---

## Adding New Features

1. **Model** - Add to `lib/data/models/` with manual `fromJson`/`toJson` methods
2. **Repository** - Add to `lib/data/repository/` implementing data access
3. **BLoC** - Add to `lib/presentation/screen/<feature>/bloc/` with events, states, and bloc
4. **Screen** - Add to `lib/presentation/screen/<feature>/`
5. **Route** - Register in `lib/routes/go_router_routes/`
6. **Mock Data** - Add JSON file to `assets/mock/` for local testing
7. **Tests** - Add corresponding tests under `test/`

---

## Contributing

1. Fork the repository
2. Clone your forked repository
3. Create your feature branch
4. Commit your changes
5. Push to the branch
6. Create a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## References
- [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/cevheri/flutter-bloc-advanced)
- [Understanding Flutter BLoC: A Comprehensive Guide](https://cevheri.medium.com/understanding-flutter-bloc-a-comprehensive-guide-7100dabe3975)
- [Flutter Documentation](https://flutter.dev/)
- [BLoC Library](https://bloclibrary.dev/)
- [flutter_bloc on pub.dev](https://pub.dev/packages/flutter_bloc)
- [go_router on pub.dev](https://pub.dev/packages/go_router)
- [Upgrade Guide - Flutter 3.41.4](docs/upgrade_flutter_3.41.4.md)
