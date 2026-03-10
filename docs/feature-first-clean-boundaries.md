# Feature-First Clean Boundaries

This document defines the target architecture for `flutter_bloc_advance`.

## Goals

- Keep the codebase feature-oriented.
- Make dependency direction explicit and enforceable.
- Preserve the current Flutter stack: `flutter_bloc`, `go_router`, manual JSON models.
- Support incremental migration without breaking the existing app.

## Top-Level Ownership

```text
lib/
  app/               # Composition root, app shell, router, bootstrap
  core/              # Cross-cutting primitives, errors, logging abstractions
  infrastructure/    # Storage, HTTP, environment, external adapters
  shared/            # Business-free reusable UI and helpers
  features/          # Business capabilities
  generated/         # Generated localization files
  l10n/              # ARB files
```

## Dependency Rules

Allowed imports:

```text
app -> features
app -> shared
app -> infrastructure
app -> core

features -> shared
features -> infrastructure
features -> core

shared -> core
infrastructure -> core
```

Forbidden imports:

```text
feature_a -> feature_b/presentation
feature_a -> feature_b/data
shared -> features
core -> shared
core -> features
infrastructure -> features/presentation
```

## Feature Structure

Each feature owns its navigation, state, and data contracts.

```text
features/<feature>/
  data/
  domain/
  application/
  presentation/
  navigation/
```

Notes:

- `domain/` stays Flutter-free when possible.
- `application/` contains `Bloc`, `Cubit`, use-case orchestration, and feature coordinators.
- `presentation/` contains pages and feature-local widgets.
- `navigation/` exposes route builders for the app router.
- `data/` contains external models and repository implementations.

## App Responsibilities

`app/` is the only place that may compose concrete implementations for the whole application.

Examples:

- Router composition
- Global providers
- Session bootstrap
- Shell layout
- Theme and localization bootstrap

`app/` must not contain feature business rules.

## Shared vs Core

Use `shared/` for business-free reusable UI:

- design system components
- dialogs
- generic widgets
- generic UI helpers

Use `core/` only for primitives that should not depend on Flutter UI concerns:

- error types
- result wrappers
- logging contracts
- small common types

Do not place theme, routes, widgets, or screens under `core/`.

## Routing Rules

- `app/router` owns route composition.
- Each feature exposes its own routes from `features/<feature>/navigation/`.
- Redirect functions must stay pure and free of data loading side effects.
- Route builders must not create repositories directly.

## State Management Rules

- UI should never instantiate repositories directly.
- Feature pages should depend on feature application state only.
- Session/auth state is app-level.
- Shell state is app-level.
- Feature state remains inside the feature module.

## Migration Strategy

- Prefer additive migration first.
- New code must target the new folders.
- Legacy folders may temporarily re-export new modules during migration.
- Delete legacy implementations only after imports have been redirected.

## Review Checklist

- Does the file live under the correct owner?
- Does the import direction respect the rules?
- Is UI free from direct repository creation?
- Is the route owned by a feature or by app shell?
- Is reusable UI placed under `shared/` instead of feature folders?
