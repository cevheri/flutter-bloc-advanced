# Advanced Flutter BLOC Template

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[Wiki](https://deepwiki.com/cevheri/flutter-bloc-advanced)

---
* This project is an open-source template built with Flutter and BLOC architecture.
* It comes with a range of features and lets you quickly get started by adding your own
  screens, models, and BLOCs. 
* The template is designed to help you build scalable and maintainable applications with ease.
* It includes public and private routes, user management, roles and permissions, dark and light
  themes, mock data or API data, API client, internationalization, access control with Flutter and
  Firebase, and CI/CD with GitHub Actions.
* The template is suitable for building applications for Android, iOS, and the web.
* It is easy to customize and extend the template to meet your specific requirements.
* The template is well-documented and easy to use.
* It is a great starting point for building your next Flutter project.
* The template has separate environments for development and production.
* It can work API and Mock data.

---

![img.png](assets/README_header.png)

---

* BLoC Pattern(Data, Models, Repository, Presentation), Environments, Configuration, Themes, IOS,
* Android/IOS and Web

---

## Out-of-the-box Features

- Public and Private Routes
- 
- Home Page
    - Private Pages
        - Admin Pages
        - User Pages
    - Public Pages
        - Guest Pages
        - Access the public pages
- Authenticate
    - Login
    - Register
    - Forgot Password
    - Update Profile
    - Change Password
- One Time Password (OTP)
    - Send OTP
    - Verify OTP
- User Management
  - User Create
  - User Update
  - User Delete
  - User List
- Account 
    - Get Account
    - Update Account
- Role-based Access Control
    - Admin Role
    - User Role
- Dark and Light Themes
- Mock data
- Rest API data
- API client
- Internationalization
- **Poppins Font Integration** - Modern typography with Poppins font family
- **Web Back Button Disabler** - Prevents browser back button on web platform
- **Font Test Widget** - Visual font testing and verification tool

---

## Development Environment

When you run the main_local.dart file, the app will use the development configuration settings. All requests will be made to the mock API.
    
```text
ProfileConstants.isProduction = false;
```

```shell
flutter run --target lib/main/main_local.dart
```

### Login
Login with username/password: admin/admin


When you run the app in the development environment, the app will use the development configuration
settings.
API runs on the mock data automatically.

```text
ProfileConstants.isProduction = false;
```

Mock data folder

```text
assets/mock/...
```

### User Roles

- Admin Account
  This is an **admin account** that has access to all the pages.
    - username: admin
    - password: admin
- User Account
  This is a **user account** that has access to the user's own pages.(Account, password, theme,
  language, etc.) (User can't access the admin pages)
    - username: user
    - password: user

## Production Environment

When you run the app in the production environment, the app will use the production configuration
settings.
API run on the real data automatically with your API URL.

```text
ProfileConstants.isProduction = true;
```

API URL

Production API URLs like these:

```text
https://mock-api.sample.tech/api/v1

https://python-mock-api.sample.tech/api/v1

https://java-mock-api.sample.tech/api/v1
```

---

## Installation

```bash
git clone https://github.com/cevheri/flutter-bloc-advanced.git
```

---

## Requirements

* for serialize and deserialize json to object

```
dart run build_runner build --delete-conflicting-outputs
```

* fix dart analyze

```
dart analyze --fix
```

* format
```shell
dart format . --line-length=120
```

---

## Use FVM

[FVM Documentation](https://fvm.app/documentation/getting-started/installation)

```shell
fvm install 3.27.1
fvm use 3.27.1
```
update environment!!!

### For MacOS
```shell
brew tap leoafarias/fvm
brew install fvm
```

### For Windows
```shell
choco install fvm
```

### For Linux
```shell
brew tap leoafarias/fvm
brew install fvm
```

## Install Dependencies

```bash
flutter pub get
```

---

## Getting Started

- Run `flutter run --target lib/main/main_local.dart` for dev environment
- Run `flutter run --target lib/main/main_prod.dart` for prod environment

flutter run dev environment

- Run `flutter run -d chrome --target lib/main/main_local.dart` for web dev environment
- Run `flutter run -d chrome --target lib/main/main_prod.dart` for web prod environment

## Usage for local environment with mock data

* Run `flutter run -d chrome --web-port 3000 --target lib/main/main_local.dart` for web dev
  environment
* Open `http://localhost:3000` in your browser
* Login with `admin` and `admin` for admin role
* Login with `user` and `user` for user role

---

## How to Build

- Run `flutter build apk --target lib/main/main_prod.dart` for android
- Run `flutter build ios --target lib/main/main_prod.dart` for ios
- Run `flutter build web --target lib/main/main_prod.dart` for web

---

## How to Run

- Run `flutter pub get`
- Run `flutter run --target lib/main/main_dev.dart` for dev environment
- Run `flutter run -d chrome --target lib/main/main_dev.dart` for web
- Run `flutter run -d ios --target lib/main/main_dev.dart` for ios
- Run `flutter run -d android --target lib/main/main_dev.dart` for android
- Run `flutter run -d web --target lib/main/main_dev.dart` for web

## How to Test

### Description

Following test should run

* test/data/model
* test/data/repository
* test/presentation/blocs
* test/presentation/screen
* test/presentation/widgets

### Run Test

- Run `flutter test`

Or 1 Thread

- Run `flutter test --concurrency=1 --test-randomize-ordering-seed=random`

### Test Coverage

The project includes comprehensive test coverage for:
- Data layer (models, repositories)
- Business logic (BLoCs)
- UI components (screens, widgets)
- Font integration and typography
- Web-specific components

### New Test Files Added

- `test/presentation/widgets/font_test_widget_test.dart` - Tests for Poppins font integration
- `test/presentation/widgets/web_back_button_disabler_test.dart` - Tests for web back button functionality

---

## Code Quality Analysis with SonarQube

GitHub Actions already implemented with SonarQube

* You can create a secret for your repository ```SONAR_TOKEN```

---

## Usage

To add new screens, models, and BLOCs, follow these steps:

1. Add New Screens
   Add your new screens to the lib/screens directory.
2. Add New Models
   Add your new model classes to the lib/models directory.
3. Add New BLOCs
   Add your new BLOC classes to the lib/bloc directory and perform necessary operations.
4. API Integration
   Integrate with APIs using the services provided in the lib/api directory.

## CI/CD with Github Actions

- [Flutter CI/CD with Github Actions](.github/workflows/build_and_test.yml)

## Firebase 

Not Implemented Yet!!!

### How to Setup Firebase

- [Flutter Firebase Setup]()
- [Flutter Firebase Setup with Github Actions]()
- [Flutter Firebase Setup with Github Actions and Firebase Hosting]()

### How to Deploy Firebase

- [Flutter Firebase Deploy]()
- [Flutter Firebase Deploy with Github Actions]()
- [Flutter Firebase Deploy with Github Actions and Firebase Hosting]()

## How to Contribute

- Fork the repository
- Clone your forked repository
- Create your feature branch
- Commit your changes
- Push to the branch
- Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [Understanding Flutter BLoC: A Comprehensive Guide](https://cevheri.medium.com/understanding-flutter-bloc-a-comprehensive-guide-7100dabe3975)
- https://flutter.dev/
- https://bloclibrary.dev/
- https://pub.dev/packages/flutter_bloc
- https://pub.dev/packages/get
- [How to deploy your docker image to cloud for free?](https://cevheri.medium.com/how-to-deploy-your-docker-image-to-cloud-for-free-6bd1c61d01ef)
