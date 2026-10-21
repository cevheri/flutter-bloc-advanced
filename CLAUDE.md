# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter BLoC Advance Template - a production-ready Flutter application using BLoC pattern for state management. Supports Android, iOS, Web, macOS, Linux, and Windows.

- **Flutter:** 3.47.7 | **Dart SDK:** ^3.13.5 | **FVM** is used for Flutter version management
- **Line width:** 120 characters (configured in `analysis_options.yaml`)

## Common Commands

```bash
# Dependencies
fvm flutter pub get

# Run locally (mock API)
fvm flutter run --target lib/main/main_local.dart

# Run production (real API)
fvm flutter run --target lib/main/main_prod.dart

# Single sign-on against the local Keycloak demo (docs/oidc.md); web must run on localhost:8081
docker compose -f tool/oidc-demo/docker-compose.yml up -d --wait
fvm flutter run -d chrome --web-port 8081 --target lib/main/main_local.dart --dart-define-from-file=tool/oidc-demo/oidc-demo.env
docker compose -f tool/oidc-demo/docker-compose.yml down -v

# Analysis & formatting
fvm dart analyze
fvm dart fix --apply
fvm dart format . --line-length=120

# Tests
fvm flutter test
fvm flutter test test/path/to/specific_test.dart          # single test file
fvm flutter test --coverage                                # with coverage
# Android JVM tests of the native Sentry scrubber (JDK 17; a Flutter Android build, such as
# fvm flutter build apk --config-only --target lib/main/main_prod.dart, writes the Gradle wrapper)
cd android && ./gradlew :app:testDebugUnitTest -Ptarget=lib/main/main_prod.dart

# Localization code generation (after editing ARB files)
fvm dart run intl_utils:generate
fvm dart format lib/generated --line-length=120   # intl_utils writes 80 columns; CI checks 120

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
- BLoCs use `Equatable` for state equality.
- Local UI state can be handled within the page, but business logic MUST be in BLoCs.

### `Bloc` vs `Cubit`

- Use **`Cubit`** when every interaction is an atomic, fire-and-forget call and the event stream adds no value (no debouncing, no concurrency policy, no historical event payload needed). Example: `LocaleCubit` (`restore`, `changeLocale`).
- Use **`Bloc`** when events carry meaningful payload, when an `EventTransformer` (debounce, restartable, droppable) is needed, or when the event log itself is valuable for replay/observability. Examples: `UserListBloc` (search debounce + delete drop-concurrent), `UserEditorBloc` (fetch/save lifecycle), `LoginBloc` (multistep auth flow).
- Default to `Bloc` for any new feature touching network requests or user input streams; reach for `Cubit` only after confirming none of the above apply.

### State Modeling — MAIN RULE

**Default to sealed state hierarchies** that leverage Dart 3's `sealed` modifier and exhaustive `switch` expressions. The compiler enforces handling of every state variant; UIs render via pattern matching.

```dart
// State (real example: lib/features/users/application/user_list_state.dart)
sealed class UserListState extends Equatable {
  const UserListState();
}
final class UserListInitial extends UserListState { /* ... */ }
final class UserListLoading extends UserListState { /* ... */ }
final class UserListLoaded extends UserListState {
  const UserListLoaded({required this.users});
  final List<UserEntity> users;
  @override List<Object?> get props => [users];
}
final class UserListDeleteSuccess extends UserListState { /* ... */ }
sealed class UserListFailure extends UserListState {
  const UserListFailure({required this.errorCode});
  final AppErrorCode errorCode; // shown via errorCode.resolve(context); the raw message only goes to the log
  @override List<Object?> get props => [errorCode];
}
final class UserListLoadFailure extends UserListFailure { /* ... */ }
final class UserListDeleteFailure extends UserListFailure {
  const UserListDeleteFailure({required super.errorCode, required this.users});
  final List<UserEntity> users; // the list stays on screen while the failure is shown
  @override List<Object?> get props => [errorCode, users];
}

// UI
BlocBuilder<UserListBloc, UserListState>(
  builder: (context, state) => switch (state) {
    UserListInitial() || UserListDeleteSuccess() => const SizedBox.shrink(),
    UserListLoading() => const Loading(),
    UserListLoaded(:final users) || UserListDeleteFailure(:final users) => UserList(users),
    UserListLoadFailure(:final errorCode) => ErrorBanner(errorCode.resolve(context)),
  },
);
```

**Use single-state + status enum only when** one of these is genuinely true:

1. **Concurrent state access:** UI must render data from one state while reacting to another (e.g., show the previously loaded list while an error banner appears for the latest refresh attempt).
2. **Transactional snapshot:** State carries a coherent bundle whose fields all evolve together (search query + filters + pagination + result set) and splitting them into sealed variants would lose meaning.
3. **Form persistence:** Thin form/CRUD wrapper where status changes but form fields persist across all states, AND no genuine state machine exists underneath.

When in doubt, prefer sealed and split the BLoC instead of growing the single state.

**UI consumers** use `switch (state) { ... }` expressions, NOT `if (state is X) ... else if (state is Y)`. Reach for `BlocSelector` only when narrowing to a slice of a variant's fields — not for type discrimination.

**Why this rule (short version):** Compile-time exhaustive matching catches forgotten states at build time; impossible-state combinations (e.g. `loading=true && error="…"`) become unrepresentable; the `copyWith` null-clearing class of bugs disappears because variants carry only their own fields. Bloc creator [Felix Angelov](https://github.com/felangel/bloc/issues/1726) treats both patterns as valid; we pick sealed because Dart 3's modifiers + switch expressions tilt the trade-off decisively in its favor for this codebase.

## Logging

- Acquire loggers via `AppLogger.getLogger('Name')` (`lib/core/logging/app_logger.dart`).
- Use SLF4J-style parameterized substitution: `_log.debug('msg: {}', [arg])` — **not** string interpolation (`_log.debug('msg: ${arg}')`).
  - Parameterized form skips `toString()` when the log level is disabled — faster, and avoids accidentally stringifying secrets carried on events with `stringify = true`.
- `AppLogger` masks email addresses as `[REDACTED_EMAIL]` and credentials (passwords, OTP codes, tokens, `Bearer` values) as `[REDACTED]` in every line it prints, and masks the credential keys of a `Map` or `List` argument (`maskEmails`, `maskSecrets` and `scrubBodyKeys` in `lib/core/security/sensitive_data_scrubber.dart`, the one policy every exit uses).
- Never put a secret into a log message, a log argument or an exception message; a class that holds one prints `[REDACTED]` in its `toString` (`test/architecture/credential_to_string_test.dart` and `log_secrets_test.dart` guard both rules).
- BLoC lifecycle transitions are logged centrally by `AppBlocObserver` (`lib/core/logging/app_bloc_observer.dart`). Do **not** override `onTransition` inside BLoCs.

## Environments

- **dev/test** → mock data from `assets/mock/*.json`
- **prod** → real API (configured in `lib/infrastructure/config/environment.dart`)
- **Sign-in mode** is a separate build-time switch, `AUTH_PROVIDER`: unset or `jwt` is the password and OTP sign-in against the backend, and `oidc` signs in through an OpenID Connect provider configured by the `OIDC_*` defines (`lib/infrastructure/config/auth_config.dart`, [`docs/oidc.md`](docs/oidc.md)).
  Both entry points accept both modes, and `jwt` mode must never construct or call anything from the OIDC path.

## Adding a New Feature

1. Create a new directory under `lib/features/<feature_name>/`.
2. Define models and repository implementations in `data/`.
3. Add Use Cases and BLoCs in `application/`.
4. Define feature-specific routes in `navigation/`.
5. Implement pages and feature-specific widgets in `presentation/`.
6. Register the feature routes in `lib/app/router/app_router.dart`.
7. Add translations to `lib/l10n/`, run `fvm dart run intl_utils:generate`, then `fvm dart format lib/generated --line-length=120`.
8. Write tests mirroring the feature structure under `test/features/<feature_name>/`.
9. Add each new repository method that sends requests through `ApiClient` to the table in `test/architecture/mock_asset_coverage_test.dart`, with the mock files it needs under `assets/mock/`.

## Testing

- `test/flutter_test_config.dart` is the global bootstrap (auto-discovered by `flutter test`). It runs once per isolate — binding init, `AppLogger.configure`, `EquatableConfig.stringify`, mocktail `registerAllFallbackValues()` — and registers a global per-test `setUp`/`tearDown` that calls `TestEnv.reset()`.
- The bootstrap also clears `rootBundle` before and after every test, including in files that opt out of `TestEnv.reset()`: an asset `Future` cached by one `testWidgets` resumes its awaiters only in that test's finished `FakeAsync` zone, so without the reset the later tests of a file never got their `assets/mock/*.json` responses (see "The asset cache" in `docs/testing-architecture.md`).
- Tests need **no** manual setup for storage/router/secure-storage. Use `TestEnv` (`test/support/test_env.dart`):
  - `TestEnv.authenticate()` for auth-dependent tests — call it in `setUp` or the test body, **never** in `setUpAll` (the global reset clears the secure store before each test).
  - `TestEnv.apiClient()` for the mock-backed `ApiClient`.
- A test file that installs its own `MethodChannel` / `SharedPreferences` mock opts out of the global reset with `setUpAll(() => TestEnv.autoReset = false);` (isolated per file). Example: `test/infrastructure/storage/local_storage_test.dart`.
- **Test doubles** — reach for a `mocktail` mock first; drop to a hand-fake only for genuine stateful behavior; Dio handlers are always handwritten:
  - **mocktail mock (default):** the `Mock*` classes in `test/mocks/mock_classes.dart`, for interface doubles configured with `when(...)` / `verify(...)` (repository / use-case / BLoC).
  - **handwritten fake:** a private `_Fake*` / `_Memory*` class next to the test when it needs real stateful behavior (in-memory store, throw-on-Nth-call, selective/sequenced failures, return-driven branching). These are **purpose-built per test** — same-named fakes in different files are not duplication; do not force them into shared "god" fakes.
  - **Dio handler stub:** a private `_Test*Handler` / `_StubInterceptor` extending Dio's `Interceptor` / `RequestInterceptorHandler` / `ResponseInterceptorHandler` / `ErrorInterceptorHandler`, to test interceptors at the Dio layer (can't be mocked cleanly).
- **Pumping:** `pumpAndSettle()` only when animations finish; its `Duration` arg is the per-pump interval (not a timeout) — prefer the bare form. For continuous animations (spinner/shimmer) use `pump(Duration)`, never `pumpAndSettle`.
- Full test structure, per-layer patterns, and guard tests: see `docs/testing-architecture.md`.
