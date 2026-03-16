# Admin System Dashboard — Design Spec

## Overview

Transform the existing Dashboard page (currently showing 404 due to missing `/api/dashboard` backend endpoint) into a **client-side Admin System Dashboard** that surfaces the state of all 10 advanced infrastructure features. No new backend API required — all data comes from client-side services.

**Access:** ROLE_ADMIN only.

## Decision Record

- **Approach chosen:** Replace existing Dashboard (Yaklaşım 1) over adding a new "System" page. Rationale: current dashboard always fails with 404, creating a bad first impression. Transforming it fixes the UX and makes infrastructure features visible.
- **Data source:** 100% client-side. No backend API dependency.
- **Scope:** Single scrollable page with 6 card sections + 4 KPI summary cards.
- **Cubit vs Bloc:** Using `Cubit` (not `Bloc` with events) because the dashboard is primarily read-heavy with simple actions (toggle, clear, reset). This matches the existing pattern — `ConnectivityCubit`, `SessionCubit` use the same approach for similar read+action mixes.
- **Use case layer skipped:** The standard `BLoC -> UseCase -> Repository` pattern is intentionally bypassed. Rationale: there is no backend repository — all data comes from infrastructure singletons already available in memory. Adding use cases would be empty pass-through wrappers with no value.
- **Cross-feature boundary:** `AppConfigEntity` will be passed into the Cubit from the widget layer (which reads `LifecycleBloc.state` via `BlocBuilder`). The Cubit itself does NOT import from `features/lifecycle/`. This preserves clean architecture boundaries.

## Page Layout

Responsive layout using existing `AppResponsiveBuilder` and `AppAdaptiveGrid`.

```
┌─────────────────────────────────────────────────────────┐
│  System Dashboard               v0.19.20    [Refresh]   │
├──────────┬──────────┬──────────┬───────────┐            │
│ Connec-  │ Circuit  │ Cache    │ Feature   │  KPI Cards  │
│ tivity   │ Breaker  │ Storage  │ Flags     │  (4 cols)   │
│ ● Online │ 3 OK     │ 12 items │ 2/3 ON    │            │
├──────────┴──────────┴──────────┴───────────┘            │
│                                                         │
│  ┌─ Circuit Breaker Health ─────────────────────────┐   │
│  │ /api/admin/users     ● Closed (healthy)    0 fail│   │
│  │ /api/authorities     ● Closed (healthy)    0 fail│   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─ Feature Flags ──────┐  ┌─ App Config ───────────┐  │
│  │ dark_mode_v2    [ON] │  │ Version: 0.19.20       │  │
│  │ export_pdf      [ON] │  │ Min Version: 0.1.0     │  │
│  │ beta_chat      [OFF] │  │ Maintenance: OFF       │  │
│  └──────────────────────┘  └─────────────────────────┘  │
│                                                         │
│  ┌─ Interceptor Chain ──────────────────────────────┐   │
│  │ 1. ConnectivityInterceptor  ● Active             │   │
│  │ 2. TokenRefreshInterceptor  ● Active             │   │
│  │ 3. ResilienceInterceptor    ● Active (0 retries) │   │
│  │ 4. CacheInterceptor         ● Active (12 cached) │   │
│  │ 5. AuthInterceptor          ● Active             │   │
│  │ 6. DevConsoleInterceptor    ● Debug only         │   │
│  │ 7. LoggingInterceptor       ● Active             │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─ Quick Actions ──────────────────────────────────┐   │
│  │ [Clear Cache] [Reset Circuit Breakers]           │   │
│  │ [Export Config] [Open Dynamic Forms]             │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

Mobile: single column, all sections stacked.
Tablet: 2-column for Feature Flags + App Config row.
Desktop: 4-column KPI cards, 2-column middle row, full-width for rest.

## State Model

```dart
enum SystemDashboardStatus { initial, loading, loaded, error }

class SystemDashboardState extends Equatable {
  final SystemDashboardStatus status;

  // KPI Card data
  final ConnectivityStatus connectivity;
  final int circuitBreakerTotal;
  final int circuitBreakerOpen;
  final int cacheItemCount;
  final int featureFlagsOn;
  final int featureFlagsTotal;

  // Detail sections
  final List<EndpointHealth> endpointHealthList;
  final Map<String, bool> featureFlags;
  final AppConfigSummary appConfig;
  final List<InterceptorInfo> interceptors;

  final String? errorMessage;
}

class EndpointHealth extends Equatable {
  final String endpoint;
  final CircuitBreakerState state; // closed, open, halfOpen
  final int failureCount;
  final DateTime? lastFailure;
}

class AppConfigSummary extends Equatable {
  final String currentVersion;
  final String minimumVersion;
  final bool maintenanceMode;
  final String environment;
}

class InterceptorInfo extends Equatable {
  final String name;
  final int order;
  final bool active;
  final String? detail;
}
```

**Note:** `cacheHitRate` removed from KPI — `SharedPrefsCacheStorage` does not currently track hit/miss counts. Only `cacheItemCount` (countable via stored keys) is included. Hit rate tracking can be added as a future enhancement.

## Cubit API

```dart
class SystemDashboardCubit extends Cubit<SystemDashboardState> {
  SystemDashboardCubit({
    required ConnectivityService connectivityService,
    required FeatureFlagService featureFlagService,
    required ResilienceInterceptor resilienceInterceptor,
    required SharedPrefsCacheStorage cacheStorage,
  });

  void load();                                    // Collect snapshot from all services
  void updateAppConfig(AppConfigSummary config);  // Called from widget layer via BlocListener on LifecycleBloc
  void toggleFeatureFlag(String key, bool value); // Toggle flag + reload
  void clearCache();                              // Clear cache storage + reload
  void resetCircuitBreakers();                    // Reset all breakers + reload
}
```

### App Config data flow (cross-feature boundary safe):

```
LifecycleBloc (features/lifecycle/) ← lives in widget tree via BlocProvider
       │
       ▼ BlocListener in DashboardHomePage (reads state.appConfig)
       │
       ▼ systemDashboardCubit.updateAppConfig(summary)
       │
       ▼ SystemDashboardState updated
```

The `SystemDashboardCubit` never imports from `features/lifecycle/`. The widget layer bridges the data — this is the standard BLoC-to-BLoC communication pattern used throughout the project.

### Reactive updates:
- `ConnectivityService.statusStream` → automatic `load()` on status change
- `FeatureFlagService` (ChangeNotifier) → listen for flag changes
- `LifecycleBloc` state changes → `BlocListener` in widget calls `updateAppConfig()`
- Manual refresh via header button

### Quick Actions navigation:
Quick action buttons like "Open Dynamic Forms" use `context.go(AppRoutesConstants.dynamicForms)` directly in the widget `onPressed` callback. The Cubit is not involved in navigation.

## Data Sources

| Dashboard Section | Service | Method | Access Pattern |
|---|---|---|---|
| Connectivity KPI | `ConnectivityService.instance` | `.currentStatus` | Singleton, always available |
| Circuit Breaker KPI + Health | `ResilienceInterceptor` | `.circuitBreakers` (new getter) | Passed via DI (see below) |
| Cache KPI | `SharedPrefsCacheStorage` | `.count()` (new method) | Passed via DI |
| Feature Flags KPI + toggles | `FeatureFlagService.instance` | `.flags`, `.setFlag()` | Singleton, always available |
| App Config | `LifecycleBloc.state` | Via `BlocListener` in widget | Widget-layer bridge, no cross-feature import |
| Interceptor Chain | `ApiClient.instance.dio.interceptors` | Read interceptor list at runtime | Dynamic, reflects actual chain |

### Required additions to existing services:

1. **`ResilienceInterceptor`** — expose `Map<String, CircuitBreaker> get circuitBreakers` (make `_breakers` accessible as unmodifiable view). Also: register as a named singleton in `AppDependencies` so the Cubit can receive it via DI.
2. **`SharedPrefsCacheStorage`** — add `Future<int> count()` method (count keys with `_cache_` prefix). Simple, no hit-rate tracking needed.
3. **`FeatureFlagService`** — expose `Map<String, bool> get flags` (if not already public).
4. **`ApiClient`** — expose the `ResilienceInterceptor` and `SharedPrefsCacheStorage` instances (store as fields during setup, provide getters). These are currently created inline and not accessible after construction.

## File Changes

### Rewrite (6 files)

| File | Action | Description |
|---|---|---|
| `features/dashboard/presentation/pages/dashboard_home_page.dart` | **Rewrite** | Entry point page. Currently creates `DashboardCubit` with `LoadDashboardUseCase`. Rewrite to read `SystemDashboardCubit` from context + add `BlocListener<LifecycleBloc>` to bridge app config data. |
| `features/dashboard/presentation/pages/dashboard_page.dart` | **Rewrite** | Body widget. Replace KPI/chart/activity UI with 6-section admin dashboard layout. |
| `features/dashboard/application/dashboard_cubit.dart` | **Rewrite** | → `SystemDashboardCubit` with client-side data collection |
| `features/dashboard/application/dashboard_state.dart` | **Rewrite** | → `SystemDashboardState` + sub-models (`EndpointHealth`, `AppConfigSummary`, `InterceptorInfo`) |
| `features/dashboard/dashboard.dart` | **Update** | Barrel export — update exports to match new files, remove deleted file references |
| `features/dashboard/navigation/dashboard_routes.dart` | **Update** | May need minor update if route builder changes |

### Delete (8 files)

| File | Action | Reason |
|---|---|---|
| `features/dashboard/application/usecases/load_dashboard_usecase.dart` | **Delete** | No backend repository, no use case needed |
| `features/dashboard/data/repositories/dashboard_api_repository.dart` | **Delete** | Backend API repo no longer needed |
| `features/dashboard/data/repositories/dashboard_mock_repository.dart` | **Delete** | Mock repo no longer needed |
| `features/dashboard/data/models/dashboard_model.dart` | **Delete** | Backend data model no longer needed |
| `features/dashboard/domain/repositories/dashboard_repository.dart` | **Delete** | Repository interface no longer needed |
| `features/dashboard/domain/entities/dashboard_entity.dart` | **Delete** | Old entity replaced by state sub-models |
| `assets/mock/dashboard.json` | **Delete** | No longer needed (was the mock data for the API repo) |
| `fl_chart` in `pubspec.yaml` | **Remove dependency** | No charts in new dashboard. Verify not used elsewhere first. |

### Update (4 files)

| File | Action | Description |
|---|---|---|
| `app/di/app_scope.dart` | **Update** | Remove `RepositoryProvider<IDashboardRepository>`, add `BlocProvider<SystemDashboardCubit>` with new dependencies |
| `app/di/app_dependencies.dart` | **Update** | Remove `createDashboardRepository()` method. Add `ResilienceInterceptor` and `SharedPrefsCacheStorage` instance getters. |
| `infrastructure/http/interceptors/resilience_interceptor.dart` | **Minor update** | Expose `circuitBreakers` getter (unmodifiable map view) |
| `infrastructure/cache/shared_prefs_cache_storage.dart` | **Minor update** | Add `Future<int> count()` method |

### Test files

| File | Action |
|---|---|
| `test/features/dashboard/application/dashboard_cubit_test.dart` | **Rewrite** — test `SystemDashboardCubit.load()`, toggle, clear, reset with mocked services |
| `test/features/dashboard/application/usecases/load_dashboard_usecase_test.dart` | **Delete** — use case removed |
| `test/features/dashboard/domain/entities/dashboard_entity_test.dart` | **Delete** — old entity removed, new sub-models tested via cubit tests |
| `test/features/dashboard/presentation/pages/dashboard_page_test.dart` | **Rewrite** — test 6 sections render for loaded/loading/error states |
| `test/features/dashboard/presentation/pages/home_screen_test.dart` | **Rewrite** — test LifecycleBloc bridge, cubit integration |
| `test/features/dashboard/navigation/dashboard_feature_routes_test.dart` | **Keep** — route structure unchanged |

### Localization

New keys to add in `lib/l10n/intl_en.arb` (and other languages):

- `system_dashboard` — "System Dashboard"
- `circuit_breaker_health` — "Circuit Breaker Health"
- `feature_flags` — "Feature Flags"
- `app_config` — "App Config"
- `interceptor_chain` — "Interceptor Chain"
- `quick_actions` — "Quick Actions" (may already exist)
- `clear_cache` — "Clear Cache"
- `reset_circuit_breakers` — "Reset Circuit Breakers"
- `export_config` — "Export Config"
- `open_dynamic_forms` — "Open Dynamic Forms"
- `endpoint` — "Endpoint"
- `healthy` — "Healthy"
- `degraded` — "Degraded"
- `open_circuit` — "Open"

Run `fvm dart run intl_utils:generate` after adding.

## UI Components Used (existing design system)

- `AppCard` (outlined variant) — each section
- `AppAdaptiveGrid` — KPI cards row
- `AppResponsiveBuilder` — tablet/desktop layout
- `AppSkeleton` — loading state
- `AppErrorState` — error fallback
- `SemanticColors` — success (green), warning (yellow), error (red) for circuit breaker states
- `Switch` (Material) — feature flag toggles
- `FilledButton.tonalIcon` — quick action buttons

## Design Constraints

- No new packages. `fl_chart` removed (verify not used elsewhere).
- No new backend endpoints. 100% client-side.
- Follows existing BLoC pattern: `Cubit<State>` with `Equatable`.
- ROLE_ADMIN gated via existing menu authority system (`menus.json`).
- Responsive: mobile (1 col), tablet (2 col), desktop (4 col KPI, 2 col middle).
- Uses existing design tokens (AppSpacing, SemanticColors, etc.).
- No cross-feature imports. AppConfig bridged via widget layer.

## Service Initialization

All services used by the dashboard are initialized during `AppBootstrap.run()`:
- `ConnectivityService.initialize()` — called at bootstrap
- `FeatureFlagService` — populated by `LifecycleBloc` at bootstrap
- `ResilienceInterceptor` — created during `ApiClient` setup (pre-login)
- `SharedPrefsCacheStorage` — created during `ApiClient` setup

The dashboard is only accessible after login (ROLE_ADMIN), which happens after bootstrap. All services are guaranteed to be initialized by the time the dashboard loads.

## Testing Strategy

- **Cubit unit tests:** Mock `ConnectivityService`, `FeatureFlagService`, `ResilienceInterceptor`, `SharedPrefsCacheStorage`. Verify `load()` produces correct state, verify `toggleFeatureFlag()`, `clearCache()`, `resetCircuitBreakers()` work correctly.
- **Widget tests:** Verify 6 sections render correctly for loaded state, loading skeleton, error state. Verify feature flag toggles call cubit method. Verify quick action buttons trigger correct actions.
- **No integration/E2E tests needed** — data comes from in-memory services, no API calls.
