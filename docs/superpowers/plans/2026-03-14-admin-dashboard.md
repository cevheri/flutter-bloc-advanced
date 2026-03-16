# Admin System Dashboard Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the broken Dashboard page into a client-side Admin System Dashboard that shows connectivity status, circuit breaker health, cache stats, feature flags, app config, and interceptor chain — all without backend API calls.

**Architecture:** Replace `DashboardCubit` (backend-dependent) with `SystemDashboardCubit` that reads from client-side singletons (ConnectivityService, FeatureFlagService, ResilienceInterceptor, SharedPrefsCacheStorage). AppConfig is bridged from LifecycleBloc via widget-layer BlocListener to avoid cross-feature imports.

**Tech Stack:** Flutter, flutter_bloc (Cubit), Equatable, existing design system (AppCard, AppAdaptiveGrid, AppResponsiveBuilder, SemanticColors)

**Spec:** `docs/superpowers/specs/2026-03-14-admin-dashboard-design.md`

---

## Chunk 1: Service Additions + Delete Old Files

### Task 1: Expose circuit breakers from ResilienceInterceptor

**Files:**
- Modify: `lib/infrastructure/http/interceptors/resilience_interceptor.dart`
- Modify: `test/infrastructure/http/interceptors/resilience_interceptor_test.dart`

- [ ] **Step 1: Add getter to ResilienceInterceptor**

In `lib/infrastructure/http/interceptors/resilience_interceptor.dart`, after the `_breakers` field (line ~40), add:

```dart
/// Unmodifiable view of per-endpoint circuit breakers for monitoring.
Map<String, CircuitBreaker> get circuitBreakers => Map.unmodifiable(_breakers);

/// Reset all circuit breakers to closed state.
void resetAll() {
  for (final breaker in _breakers.values) {
    breaker.reset();
  }
  _log.info('All circuit breakers reset');
}
```

- [ ] **Step 2: Add test for new getter and resetAll**

Append to `test/infrastructure/http/interceptors/resilience_interceptor_test.dart`:

```dart
group('circuitBreakers getter', () {
  test('exposes registered breakers as unmodifiable map', () {
    // trigger a request to register a breaker
    final options = RequestOptions(path: '/test');
    final handler = MockRequestInterceptorHandler();
    interceptor.onRequest(options, handler);

    final breakers = interceptor.circuitBreakers;
    expect(breakers, isA<Map<String, CircuitBreaker>>());
    expect(breakers.containsKey('/test'), isTrue);
    expect(() => (breakers as dynamic)['/new'] = CircuitBreaker(), throwsA(isA<UnsupportedError>()));
  });
});

group('resetAll', () {
  test('resets all breakers to closed state', () {
    final options = RequestOptions(path: '/test');
    final handler = MockRequestInterceptorHandler();
    interceptor.onRequest(options, handler);

    interceptor.resetAll();
    final breakers = interceptor.circuitBreakers;
    for (final breaker in breakers.values) {
      expect(breaker.state, CircuitBreakerState.closed);
      expect(breaker.failureCount, 0);
    }
  });
});
```

- [ ] **Step 3: Run tests**

Run: `fvm flutter test test/infrastructure/http/interceptors/resilience_interceptor_test.dart`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add lib/infrastructure/http/interceptors/resilience_interceptor.dart test/infrastructure/http/interceptors/resilience_interceptor_test.dart
git commit -m "feat(dashboard): expose circuit breakers getter and resetAll on ResilienceInterceptor"
```

---

### Task 2: Add count() to SharedPrefsCacheStorage

**Files:**
- Modify: `lib/infrastructure/cache/shared_prefs_cache_storage.dart`
- Modify: `test/infrastructure/cache/shared_prefs_cache_storage_test.dart`

- [ ] **Step 1: Add count method**

In `lib/infrastructure/cache/shared_prefs_cache_storage.dart`, add after the `clear()` method:

```dart
/// Returns the number of cached entries (keys with the cache prefix).
Future<int> count() async {
  final prefs = await _instance;
  return prefs.getKeys().where((k) => k.startsWith(_prefix)).length;
}
```

- [ ] **Step 2: Add test**

Append to `test/infrastructure/cache/shared_prefs_cache_storage_test.dart`:

```dart
group('count', () {
  test('returns 0 when empty', () async {
    expect(await storage.count(), 0);
  });

  test('returns correct count after writes', () async {
    await storage.write('a', 'data1');
    await storage.write('b', 'data2');
    await storage.write('c', 'data3');
    expect(await storage.count(), 3);
  });

  test('returns 0 after clear', () async {
    await storage.write('a', 'data1');
    await storage.clear();
    expect(await storage.count(), 0);
  });
});
```

- [ ] **Step 3: Run tests**

Run: `fvm flutter test test/infrastructure/cache/shared_prefs_cache_storage_test.dart`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add lib/infrastructure/cache/shared_prefs_cache_storage.dart test/infrastructure/cache/shared_prefs_cache_storage_test.dart
git commit -m "feat(dashboard): add count() to SharedPrefsCacheStorage"
```

---

### Task 3: Delete old dashboard files and clean DI

**Files:**
- Delete: `lib/features/dashboard/application/usecases/load_dashboard_usecase.dart`
- Delete: `lib/features/dashboard/data/repositories/dashboard_api_repository.dart`
- Delete: `lib/features/dashboard/data/repositories/dashboard_mock_repository.dart`
- Delete: `lib/features/dashboard/data/models/dashboard_model.dart`
- Delete: `lib/features/dashboard/domain/repositories/dashboard_repository.dart`
- Delete: `lib/features/dashboard/domain/entities/dashboard_entity.dart`
- Delete: `assets/mock/dashboard.json`
- Delete: `test/features/dashboard/application/usecases/load_dashboard_usecase_test.dart`
- Delete: `test/features/dashboard/domain/entities/dashboard_entity_test.dart`
- Modify: `lib/app/di/app_dependencies.dart`
- Modify: `lib/app/di/app_scope.dart`

- [ ] **Step 1: Delete old source files**

```bash
rm lib/features/dashboard/application/usecases/load_dashboard_usecase.dart
rm lib/features/dashboard/data/repositories/dashboard_api_repository.dart
rm lib/features/dashboard/data/repositories/dashboard_mock_repository.dart
rm lib/features/dashboard/data/models/dashboard_model.dart
rm lib/features/dashboard/domain/repositories/dashboard_repository.dart
rm lib/features/dashboard/domain/entities/dashboard_entity.dart
rm assets/mock/dashboard.json
rm test/features/dashboard/application/usecases/load_dashboard_usecase_test.dart
rm test/features/dashboard/domain/entities/dashboard_entity_test.dart
rmdir lib/features/dashboard/application/usecases 2>/dev/null || true
rmdir lib/features/dashboard/data/repositories 2>/dev/null || true
rmdir lib/features/dashboard/data/models 2>/dev/null || true
rmdir lib/features/dashboard/data 2>/dev/null || true
rmdir lib/features/dashboard/domain/repositories 2>/dev/null || true
rmdir lib/features/dashboard/domain/entities 2>/dev/null || true
rmdir lib/features/dashboard/domain 2>/dev/null || true
rmdir test/features/dashboard/application/usecases 2>/dev/null || true
rmdir test/features/dashboard/domain/entities 2>/dev/null || true
rmdir test/features/dashboard/domain 2>/dev/null || true
```

- [ ] **Step 2: Clean AppDependencies**

In `lib/app/di/app_dependencies.dart`:
- Remove imports for `dashboard_api_repository.dart`, `dashboard_mock_repository.dart`, `dashboard_repository.dart` (the domain interface)
- Remove the `createDashboardRepository()` method

- [ ] **Step 3: Clean AppScope**

In `lib/app/di/app_scope.dart`:
- Remove `import ...dashboard/domain/repositories/dashboard_repository.dart`
- Remove `RepositoryProvider<IDashboardRepository>(create: (_) => dependencies.createDashboardRepository()),`

- [ ] **Step 4: Verify compilation**

Run: `fvm dart analyze`
Expected: 0 issues (some files will have broken imports — that's OK, we'll fix them in the next tasks)

Note: The project will NOT compile yet because `dashboard_cubit.dart` and `dashboard_home_page.dart` still reference deleted files. That's expected — we rewrite them in the next tasks.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor(dashboard): delete old backend-dependent dashboard files and clean DI"
```

---

## Chunk 2: State Model + Cubit

### Task 4: Write SystemDashboardState

**Files:**
- Rewrite: `lib/features/dashboard/application/dashboard_state.dart`

- [ ] **Step 1: Rewrite dashboard_state.dart**

Replace the entire contents of `lib/features/dashboard/application/dashboard_state.dart` with the new state model. This file uses `part of` so it stays as a part of the cubit file.

```dart
part of 'dashboard_cubit.dart';

enum SystemDashboardStatus { initial, loading, loaded, error }

class SystemDashboardState extends Equatable {
  final SystemDashboardStatus status;

  // KPI data
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

  const SystemDashboardState({
    this.status = SystemDashboardStatus.initial,
    this.connectivity = ConnectivityStatus.online,
    this.circuitBreakerTotal = 0,
    this.circuitBreakerOpen = 0,
    this.cacheItemCount = 0,
    this.featureFlagsOn = 0,
    this.featureFlagsTotal = 0,
    this.endpointHealthList = const [],
    this.featureFlags = const {},
    this.appConfig = const AppConfigSummary(),
    this.interceptors = const [],
    this.errorMessage,
  });

  SystemDashboardState copyWith({
    SystemDashboardStatus? status,
    ConnectivityStatus? connectivity,
    int? circuitBreakerTotal,
    int? circuitBreakerOpen,
    int? cacheItemCount,
    int? featureFlagsOn,
    int? featureFlagsTotal,
    List<EndpointHealth>? endpointHealthList,
    Map<String, bool>? featureFlags,
    AppConfigSummary? appConfig,
    List<InterceptorInfo>? interceptors,
    String? errorMessage,
  }) {
    return SystemDashboardState(
      status: status ?? this.status,
      connectivity: connectivity ?? this.connectivity,
      circuitBreakerTotal: circuitBreakerTotal ?? this.circuitBreakerTotal,
      circuitBreakerOpen: circuitBreakerOpen ?? this.circuitBreakerOpen,
      cacheItemCount: cacheItemCount ?? this.cacheItemCount,
      featureFlagsOn: featureFlagsOn ?? this.featureFlagsOn,
      featureFlagsTotal: featureFlagsTotal ?? this.featureFlagsTotal,
      endpointHealthList: endpointHealthList ?? this.endpointHealthList,
      featureFlags: featureFlags ?? this.featureFlags,
      appConfig: appConfig ?? this.appConfig,
      interceptors: interceptors ?? this.interceptors,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status, connectivity, circuitBreakerTotal, circuitBreakerOpen,
        cacheItemCount, featureFlagsOn, featureFlagsTotal,
        endpointHealthList, featureFlags, appConfig, interceptors, errorMessage,
      ];
}

class EndpointHealth extends Equatable {
  final String endpoint;
  final CircuitBreakerState state;
  final int failureCount;
  final DateTime? lastFailure;

  const EndpointHealth({
    required this.endpoint,
    required this.state,
    this.failureCount = 0,
    this.lastFailure,
  });

  @override
  List<Object?> get props => [endpoint, state, failureCount, lastFailure];
}

class AppConfigSummary extends Equatable {
  final String currentVersion;
  final String minimumVersion;
  final bool maintenanceMode;
  final String environment;

  const AppConfigSummary({
    this.currentVersion = '',
    this.minimumVersion = '',
    this.maintenanceMode = false,
    this.environment = '',
  });

  @override
  List<Object?> get props => [currentVersion, minimumVersion, maintenanceMode, environment];
}

class InterceptorInfo extends Equatable {
  final String name;
  final int order;
  final bool active;
  final String? detail;

  const InterceptorInfo({
    required this.name,
    required this.order,
    this.active = true,
    this.detail,
  });

  @override
  List<Object?> get props => [name, order, active, detail];
}
```

- [ ] **Step 2: No standalone test needed** — state model tested via cubit tests in Task 5.

---

### Task 5: Write SystemDashboardCubit

**Files:**
- Rewrite: `lib/features/dashboard/application/dashboard_cubit.dart`
- Rewrite: `test/features/dashboard/application/dashboard_cubit_test.dart`

- [ ] **Step 1: Rewrite dashboard_cubit.dart**

Replace entire contents of `lib/features/dashboard/application/dashboard_cubit.dart`:

```dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';

part 'dashboard_state.dart';

/// Client-side system dashboard cubit.
///
/// Reads from infrastructure singletons — no backend API calls.
class SystemDashboardCubit extends Cubit<SystemDashboardState> {
  final ConnectivityService _connectivityService;
  final FeatureFlagService _featureFlagService;
  final ResilienceInterceptor _resilienceInterceptor;
  final SharedPrefsCacheStorage _cacheStorage;

  StreamSubscription<ConnectivityStatus>? _connectivitySub;
  VoidCallback? _flagListener;

  SystemDashboardCubit({
    required ConnectivityService connectivityService,
    required FeatureFlagService featureFlagService,
    required ResilienceInterceptor resilienceInterceptor,
    required SharedPrefsCacheStorage cacheStorage,
  })  : _connectivityService = connectivityService,
        _featureFlagService = featureFlagService,
        _resilienceInterceptor = resilienceInterceptor,
        _cacheStorage = cacheStorage,
        super(const SystemDashboardState()) {
    _connectivitySub = _connectivityService.statusStream.listen((_) => load());
    _flagListener = () => load();
    _featureFlagService.addListener(_flagListener!);
  }

  /// Collect a snapshot from all services.
  Future<void> load() async {
    emit(state.copyWith(status: SystemDashboardStatus.loading));
    try {
      final connectivity = _connectivityService.currentStatus;

      final breakers = _resilienceInterceptor.circuitBreakers;
      final endpointHealth = breakers.entries.map((e) {
        return EndpointHealth(
          endpoint: e.key,
          state: e.value.state,
          failureCount: e.value.failureCount,
        );
      }).toList();
      final openCount = breakers.values.where((b) => b.state == CircuitBreakerState.open).length;

      final cacheCount = await _cacheStorage.count();

      final flags = _featureFlagService.allFlags;
      final flagsOn = flags.values.where((v) => v).length;

      final interceptors = _buildInterceptorList(cacheCount);

      emit(state.copyWith(
        status: SystemDashboardStatus.loaded,
        connectivity: connectivity,
        circuitBreakerTotal: breakers.length,
        circuitBreakerOpen: openCount,
        cacheItemCount: cacheCount,
        featureFlagsOn: flagsOn,
        featureFlagsTotal: flags.length,
        endpointHealthList: endpointHealth,
        featureFlags: flags,
        interceptors: interceptors,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SystemDashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Called from widget layer when LifecycleBloc emits new app config.
  void updateAppConfig(AppConfigSummary config) {
    emit(state.copyWith(appConfig: config));
  }

  /// Toggle a feature flag.
  Future<void> toggleFeatureFlag(String key, bool value) async {
    _featureFlagService.setFlag(key, value);
    // load() will be triggered by the ChangeNotifier listener
  }

  /// Clear all cached data.
  Future<void> clearCache() async {
    await _cacheStorage.clear();
    await load();
  }

  /// Reset all circuit breakers to closed.
  Future<void> resetCircuitBreakers() async {
    _resilienceInterceptor.resetAll();
    await load();
  }

  List<InterceptorInfo> _buildInterceptorList(int cacheCount) {
    final breakers = _resilienceInterceptor.circuitBreakers;
    final retryCount = breakers.values.fold<int>(0, (sum, b) => sum + b.failureCount);
    return [
      const InterceptorInfo(name: 'ConnectivityInterceptor', order: 1),
      const InterceptorInfo(name: 'AuthInterceptor', order: 2),
      const InterceptorInfo(name: 'TokenRefreshInterceptor', order: 3),
      InterceptorInfo(name: 'ResilienceInterceptor', order: 4, detail: '$retryCount failures'),
      InterceptorInfo(name: 'CacheInterceptor', order: 5, detail: '$cacheCount cached'),
      const InterceptorInfo(name: 'DevConsoleInterceptor', order: 6, active: false, detail: 'Debug only'),
      const InterceptorInfo(name: 'LoggingInterceptor', order: 7),
    ];
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    if (_flagListener != null) {
      _featureFlagService.removeListener(_flagListener!);
    }
    return super.close();
  }
}
```

- [ ] **Step 2: Write cubit tests**

Rewrite `test/features/dashboard/application/dashboard_cubit_test.dart` with comprehensive tests for load(), updateAppConfig(), toggleFeatureFlag(), clearCache(), resetCircuitBreakers(), stream subscriptions, and close().

Mock: `ConnectivityService`, `FeatureFlagService`, `ResilienceInterceptor`, `SharedPrefsCacheStorage`.

- [ ] **Step 3: Run tests**

Run: `fvm flutter test test/features/dashboard/application/dashboard_cubit_test.dart`
Expected: All PASS

- [ ] **Step 4: Run analyze**

Run: `fvm dart analyze lib/features/dashboard/application/`
Expected: 0 issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/application/ test/features/dashboard/application/
git commit -m "feat(dashboard): implement SystemDashboardCubit with client-side data collection"
```

---

## Chunk 3: UI + DI Integration

### Task 6: Rewrite DashboardPage (6-section admin UI)

**Files:**
- Rewrite: `lib/features/dashboard/presentation/pages/dashboard_page.dart`

- [ ] **Step 1: Rewrite dashboard_page.dart**

Replace entire file with 6-section layout:
- `_DashboardHeader` — title + version + refresh button
- `_KpiCards` — 4 cards (connectivity, circuit breaker, cache, feature flags) using `AppAdaptiveGrid`
- `_CircuitBreakerHealthSection` — table of endpoints with colored status dots
- `_FeatureFlagsSection` + `_AppConfigSection` — side by side on tablet/desktop via `AppResponsiveBuilder`
- `_InterceptorChainSection` — ordered list of interceptors with status
- `_QuickActionsSection` — action buttons (clear cache, reset breakers, open dynamic forms)

Use `BlocBuilder<SystemDashboardCubit, SystemDashboardState>` with status-based rendering:
- `initial/loading` → `_DashboardSkeleton` (reuse existing pattern)
- `error` → `AppErrorState` with retry
- `loaded` → full content

Color coding: `SemanticColors.success` (green) for closed/online, `colorScheme.error` (red) for open/offline, `Colors.orange` for halfOpen.

- [ ] **Step 2: Verify no import violations**

The page file imports only from:
- `flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart` (same feature)
- `flutter_bloc_advance/shared/design_system/...` (shared)
- `flutter_bloc_advance/infrastructure/connectivity/...` (infrastructure — for ConnectivityStatus enum)
- `flutter_bloc_advance/infrastructure/http/circuit_breaker.dart` (infrastructure — for CircuitBreakerState enum)

No cross-feature imports.

---

### Task 7: Rewrite DashboardHomePage + DI integration

**Files:**
- Rewrite: `lib/features/dashboard/presentation/pages/dashboard_home_page.dart`
- Modify: `lib/app/di/app_scope.dart`
- Update: `lib/features/dashboard/dashboard.dart`

- [ ] **Step 1: Rewrite dashboard_home_page.dart**

Replace entire file. Key changes:
- Remove `BlocProvider<DashboardCubit>` (cubit now comes from AppScope)
- Add `BlocListener<LifecycleBloc>` to bridge AppConfig
- Keep `AccountBloc` loading logic

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({super.key});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final accountBloc = context.read<AccountBloc>();
      if (accountBloc.state.status == AccountStatus.initial) {
        accountBloc.add(const AccountFetchEvent());
      }
      // Initial dashboard load
      context.read<SystemDashboardCubit>().load();
      // Bridge initial app config
      _syncAppConfig();
    });
  }

  void _syncAppConfig() {
    try {
      final lifecycleState = context.read<LifecycleBloc>().state;
      final config = lifecycleState.appConfig;
      if (config != null) {
        context.read<SystemDashboardCubit>().updateAppConfig(
          AppConfigSummary(
            currentVersion: AppConstants.appVersion,
            minimumVersion: config.minimumVersion ?? '',
            maintenanceMode: config.maintenanceMode ?? false,
            environment: ProfileConstants.isProduction ? 'prod' : 'dev',
          ),
        );
      }
    } catch (_) {
      // LifecycleBloc may not be in tree
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LifecycleBloc, LifecycleState>(
      listenWhen: (prev, curr) => prev.appConfig != curr.appConfig,
      listener: (context, lifecycleState) {
        final config = lifecycleState.appConfig;
        if (config != null) {
          context.read<SystemDashboardCubit>().updateAppConfig(
            AppConfigSummary(
              currentVersion: AppConstants.appVersion,
              minimumVersion: config.minimumVersion ?? '',
              maintenanceMode: config.maintenanceMode ?? false,
              environment: ProfileConstants.isProduction ? 'prod' : 'dev',
            ),
          );
        }
      },
      child: BlocBuilder<AccountBloc, AccountState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, accountState) {
          if (accountState.status == AccountStatus.success) {
            return const DashboardPage();
          }
          if (accountState.status == AccountStatus.loading || accountState.status == AccountStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

Note: This imports from `features/lifecycle/` — but only the BlocListener reads from it. The Cubit itself never imports lifecycle. The DashboardHomePage is in the `features/dashboard/` scope and communicates between blocs via the widget layer — this is the approved cross-feature communication pattern.

- [ ] **Step 2: Register SystemDashboardCubit in AppScope**

In `lib/app/di/app_scope.dart`, add to the `MultiBlocProvider.providers` list:

```dart
BlocProvider<SystemDashboardCubit>(
  create: (_) => SystemDashboardCubit(
    connectivityService: ConnectivityService.instance,
    featureFlagService: FeatureFlagService.instance,
    resilienceInterceptor: ResilienceInterceptor.instance,
    cacheStorage: SharedPrefsCacheStorage.instance,
  ),
),
```

This requires making `ResilienceInterceptor` and `SharedPrefsCacheStorage` accessible as singletons. Read current ApiClient setup to determine access pattern. If they are created inline in `_createDio()`, store them as static fields on `ApiClient` and expose getters, or use a singleton pattern on the interceptor/storage classes themselves.

- [ ] **Step 3: Update barrel export**

Update `lib/features/dashboard/dashboard.dart` to export only the remaining files (remove deleted file exports).

- [ ] **Step 4: Run full test suite**

Run: `fvm flutter test`
Expected: All PASS

- [ ] **Step 5: Run analyze**

Run: `fvm dart analyze`
Expected: 0 issues

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(dashboard): integrate SystemDashboardCubit with DI and rewrite home page"
```

---

### Task 8: Widget tests for dashboard page

**Files:**
- Rewrite: `test/features/dashboard/presentation/pages/dashboard_page_test.dart`
- Rewrite: `test/features/dashboard/presentation/pages/home_screen_test.dart`

- [ ] **Step 1: Write dashboard_page_test.dart**

Test 6 sections render for loaded state. Test loading skeleton. Test error state with retry. Test feature flag toggle calls cubit. Test quick action buttons.

Mock: `SystemDashboardCubit` using `MockBloc` from `bloc_test`.

- [ ] **Step 2: Write home_screen_test.dart**

Test LifecycleBloc bridge triggers updateAppConfig. Test AccountBloc loading. Test DashboardPage renders when account loaded.

- [ ] **Step 3: Run tests**

Run: `fvm flutter test test/features/dashboard/`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add test/features/dashboard/
git commit -m "test(dashboard): add widget tests for admin dashboard page and home screen"
```

---

## Chunk 4: Localization + Cleanup + Verify

### Task 9: Add localization keys

**Files:**
- Modify: `lib/l10n/intl_en.arb`
- Modify: `lib/l10n/intl_tr.arb` (if exists)

- [ ] **Step 1: Add keys to intl_en.arb**

Add the following keys:
- `system_dashboard`: "System Dashboard"
- `circuit_breaker_health`: "Circuit Breaker Health"
- `feature_flags`: "Feature Flags"
- `app_config`: "App Config"
- `interceptor_chain`: "Interceptor Chain"
- `clear_cache`: "Clear Cache"
- `reset_circuit_breakers`: "Reset Circuit Breakers"
- `export_config`: "Export Config"
- `open_dynamic_forms`: "Open Dynamic Forms"
- `healthy`: "Healthy"
- `degraded`: "Degraded"
- `open_circuit`: "Open"

- [ ] **Step 2: Run intl_utils**

Run: `fvm dart run intl_utils:generate`
Expected: Generated files updated

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/ lib/generated/
git commit -m "feat(dashboard): add localization keys for admin dashboard"
```

---

### Task 10: Remove fl_chart dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Check if fl_chart is used elsewhere**

Run: `grep -r "fl_chart" lib/ --include="*.dart" | grep -v dashboard`
Expected: No results (fl_chart only used in old dashboard)

- [ ] **Step 2: Remove from pubspec.yaml**

Remove `fl_chart:` line from `pubspec.yaml` dependencies.

- [ ] **Step 3: Run pub get**

Run: `fvm flutter pub get`
Expected: Success

- [ ] **Step 4: Run full tests + analyze**

Run: `fvm dart analyze && fvm flutter test`
Expected: 0 issues, all tests PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(dashboard): remove fl_chart dependency (no longer used)"
```

---

### Task 11: Final verification

- [ ] **Step 1: Run full test suite with coverage**

Run: `fvm flutter test --coverage`
Expected: All tests PASS, coverage improved from 64%

- [ ] **Step 2: Run dart analyze**

Run: `fvm dart analyze`
Expected: 0 issues

- [ ] **Step 3: Run dart format**

Run: `fvm dart format . --line-length=120`
Expected: All files formatted

- [ ] **Step 4: Build web**

Run: `fvm flutter build web --target lib/main/main_prod.dart`
Expected: Build succeeds

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat(dashboard): complete admin system dashboard transformation"
```
