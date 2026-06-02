# Design — Replace global config + static `ApiClient` with immutable `AppConfig` and DI-injected `ApiClient`

- **Issue:** [#144](https://github.com/cevheri/flutter-bloc-advanced/issues/144) — *Replace `ProfileConstants` global map with immutable `AppConfig` injected via DI*
- **Supersedes:** PR [#145](https://github.com/cevheri/flutter-bloc-advanced/pull/145) (draft) — keeps its `AppConfig` design, closes it as superseded
- **Branch:** `feat/144-appconfig-apiclient-di` (from `main`)
- **Date:** 2026-06-02
- **Flutter/Dart:** 3.44.0 / Dart 3.12 — no 3.44 breaking change affects DI, providers, BLoC, or static patterns; direction (Dart 3 switch expressions, `final class`, null-aware spreads) reinforces this design.

## 1. Problem

Two coupled global-state problems:

1. **`ProfileConstants`** (issue #144): a mutable global `static Map<String, dynamic>? _config`, environment re-derived by map *identity*, `dynamic` getters with `null!`, magic-string keys.
2. **`ApiClient`**: a fully **static** class (`ApiClient.get/post/...`, `static Dio? _dio`, `static AppConfig`, `static secureStorage`, `static onSessionExpired`, `setTestInstance`/`reset`). PR #145 migrated `ProfileConstants` → `AppConfig` but **kept the config as a mutable static on `ApiClient`** (`ApiClient.appConfig = …`), reproducing the exact anti-pattern the issue targets and creating a **dual source of truth** (DI-provided `AppConfig` vs `ApiClient.appConfig` diverge outside bootstrap).

This design eliminates **all** mutable global state in the config + HTTP layer. End state: **zero mutable global statics**; one immutable `AppConfig` and one `ApiClient`, both born in `AppDependencies` and injected through the existing `RepositoryProvider` DI spine.

## 2. Goals / Non-goals

**Goals**
- Immutable, typed `AppConfig` (keep #145's `final class` design) as the single config object.
- `ApiClient` becomes an injectable instance; repositories receive it via constructor.
- One shared `ApiClient`/`AppConfig` provided once via DI; consumers read from DI, never from a global.
- Delete `ApiClient.reset()`/`setTestInstance` ceremony — isolation becomes structural.
- All 1543 tests green; `dart analyze` clean; `dart format` clean.

**Non-goals (explicitly out of scope)**
- Wiring `onSessionExpired` (currently dormant — never assigned in `lib/`; preserved as a nullable ctor param).
- Converting other `.instance` singletons (`ResilienceInterceptor`, `ConnectivityService`, `FeatureFlagService`, `SharedPrefsCacheStorage`) to DI — separate concern.
- Any change to interceptor behavior, error mapping, certificate pinning, or mock-data serving.

## 3. Design

### 3.1 `AppConfig` (from #145, kept as-is)

`final class AppConfig` in `lib/infrastructure/config/environment.dart`: `Environment environment`, `String? apiBaseUrl`, `List<String> certificatePins`, `Duration? idleTimeout`; `const` `.dev()/.test()/.prod()` constructors + `factory AppConfig.fromEnvironment(Environment)`; `isProduction/isDevelopment/isTest` getters; prod-only `sentryDsn` (`String.fromEnvironment`). `ProfileConstants` + `_Config` deleted.

### 3.2 `ApiClient` → instance (`lib/infrastructure/http/api_client.dart`)

```dart
class ApiClient {
  ApiClient({
    required this.appConfig,
    ISecureStorage? secureStorage,
    this.onSessionExpired,
    Dio? dio,                       // test seam — replaces setTestInstance()
  })  : _secureStorage = secureStorage,
        _dio = dio;

  final AppConfig appConfig;
  final OnSessionExpired? onSessionExpired;
  final ISecureStorage? _secureStorage;
  Dio? _dio;
  List<InterceptorChainEntry> _chainSnapshot = const [];

  Dio get instance => _dio ??= _createDio();
  List<InterceptorChainEntry> get interceptorChainSnapshot => List.unmodifiable(_chainSnapshot);

  Future<Response<String>> get(...) { ... }   // get/post/put/patch/delete: static → instance
  Dio _createDio() { ... }                     // reads this.appConfig / this._secureStorage / this.onSessionExpired

  static String decodeUTF8(String s) { ... }   // PURE util → stays static (no global state)
  static AppException _mapDioException(...) { } // pure mappers → stay static
}
```

**Removed:** `static Dio? _dio`, `static Dio? _testDio`, `static AppConfig _appConfig` + setter, `static ISecureStorage? secureStorage`, `static OnSessionExpired? onSessionExpired`, `setTestInstance`, `resetTestInstance`, `reset`. `InterceptorChainEntry` and the static pure functions (`decodeUTF8`, `_mapDioException`, `_mapBadResponse`, `_mapUnknown`, `_serializeData`) stay.

### 3.3 Repositories

Exactly **six** repositories issue HTTP (confirmed by grep); each takes `ApiClient` via constructor (required, no default — nothing ambient):

- `UserRepository(this._apiClient)`, `AccountRepository(this._apiClient)`, `AuthorityRepositoryImpl(this._apiClient)`, `DynamicFormRepository(this._apiClient)`, `LifecycleRepository(this._apiClient)`.
- Auth login repo takes both: `LoginRepository({required ISecureStorage secureStorage, required ApiClient apiClient})`.
- **Unchanged (no HTTP — verified):** `AuthSessionRepository` and `MenuRepository` make zero `ApiClient` calls, so their constructors and tests are NOT touched.
- `ApiClient.get(...)` calls become `_apiClient.get(...)`; `ApiClient.decodeUTF8(...)` stays a static call (pure util).

### 3.4 DI wiring

`AppDependencies` (stays `const`-constructible, `appConfig` only):
```dart
ApiClient createApiClient(ISecureStorage secureStorage) =>
    ApiClient(appConfig: appConfig, secureStorage: secureStorage);
IUserRepository createUserRepository(ApiClient api) => UserRepository(api);
// …one per repo; auth repos take (secureStorage, api)
```

`AppScope` (`MultiRepositoryProvider`, order: `ISecureStorage` → `AppConfig` → `ApiClient` → repos):
```dart
RepositoryProvider<AppConfig>.value(value: dependencies.appConfig),
RepositoryProvider<ApiClient>(create: (ctx) => dependencies.createApiClient(ctx.read<ISecureStorage>())),
RepositoryProvider<IUserRepository>(create: (ctx) => dependencies.createUserRepository(ctx.read<ApiClient>())),
// …other repos read ctx.read<ApiClient>()
```

`SystemDashboardCubit`: inject `apiClient: ctx.read<ApiClient>()`, read `apiClient.interceptorChainSnapshot` (was static). `dashboard_home_page` env read uses `context.read<AppConfig>()` (guarded — see 3.6).

### 3.5 Bootstrap

`AppBootstrap.run` drops all `ApiClient.xxx =` static assignments. It still creates the shared `ISecureStorage` (for migration) and passes it to `App`; that same instance flows into `createApiClient` via DI, so the migration-vs-runtime single-source-of-truth (today guarded by comments + discipline) becomes **structural**. `AppConfig` built once via `AppConfig.fromEnvironment(config.environment)` and passed into `AppDependencies`.

### 3.6 Review-finding fixes folded in

- **Finding #2 (dual source of truth):** eliminated by construction — one `AppConfig`, one `ApiClient`, single DI spine.
- **Finding #3 (unguarded `context.read<AppConfig>()` in `dashboard_home_page`):** the read sits outside the `try/catch` that guards the sibling `LifecycleBloc` read. Fix: read `AppConfig` defensively consistent with that guard (e.g. `context.read<AppConfig>()` inside the same resilience boundary, or `read<AppConfig?>` baseline fallback) so a dashboard pumped without the provider degrades instead of throwing.

## 4. Test strategy

Principle: **tests construct what they use; nothing ambient.**

`test_utils.dart`: remove `ApiClient.appConfig/secureStorage/reset`. Add a factory:
```dart
static ApiClient apiClient({Dio? dio}) => ApiClient(
    appConfig: const AppConfig.test(),
    secureStorage: FlutterSecureStorageAdapter(), dio: dio);
```
(test `AppConfig` → `MockInterceptor` serves `assets/mock/*.json`; shared secure adapter → same MethodChannel mock the repo layer reads.)

Mechanical sweep (~34 files):
- Concrete repo construction `XRepository()` → `XRepository(TestUtils.apiClient())` (repo-impl, use-case, some bloc/presentation tests).
- `ApiClient.setTestInstance(testDio)` → `dio: testDio` ctor arg (dynamic_form tests, `api_client_test` prod group).
- Delete `ApiClient.reset()` + global re-wiring from `setUp`/`tearDown`.
- `api_client_test.dart`: rewrite to instance form, incl. `interceptorChainSnapshot` + `decodeUTF8` groups.
- Tests that **mock** repos (mocktail) are unaffected.

## 5. Build sequence (TDD, suite green at each step)

1. `AppConfig` in `environment.dart` + `environment_test.dart` (re-apply #145 design). Delete `ProfileConstants`.
2. Rewrite `api_client_test.dart` to the new instance contract (red) → convert `ApiClient` to instance (green). Keep static pure utils.
3. Convert repositories one feature at a time; update their impl tests as each converts (green per feature).
4. Wire `AppDependencies` + `AppScope` + bootstrap + `SystemDashboardCubit`; fix Finding #3 in `dashboard_home_page`.
5. Sweep remaining use-case/bloc/presentation tests + `test_utils`.
6. Gates: `fvm flutter test` (1543 green), `fvm dart analyze` (clean), `fvm dart format . --line-length=120`.
7. PR: fresh branch → new PR closing #144; close #145 as superseded with a note.

## 6. Risks

- **Largest risk — test churn (~34 files):** mitigated by the single `TestUtils.apiClient()` helper (one-token edits) and feature-by-feature conversion keeping the suite green.
- **Provider ordering:** `ISecureStorage` must precede `ApiClient` must precede repos in `AppScope` (same constraint `IAuthRepository` already lives under).
- **Hidden concrete-repo construction** in tests not caught by grep: surfaced by failing tests during the sweep.
- **Behavior parity:** no interceptor/error/pinning/mock logic changes; `onSessionExpired` stays dormant (no behavior change).
