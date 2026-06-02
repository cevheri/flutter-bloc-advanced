# AppConfig + DI-injected ApiClient Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the global `ProfileConstants` map with an immutable `AppConfig`, and the static `ApiClient` with an instance injected through the existing `RepositoryProvider` DI spine — eliminating all mutable global state in the config + HTTP layer.

**Architecture:** Expand → Migrate → Contract. First introduce `AppConfig` and re-establish behavior parity (≈ PR #145). Then add an instance API to `ApiClient` *alongside* a thin temporary static facade so nothing breaks. Migrate each repository/consumer to the injected instance one at a time (full suite green after every commit). Finally delete the static facade and all static config — leaving zero globals.

**Tech Stack:** Flutter 3.44 / Dart 3.12, `flutter_bloc` `RepositoryProvider` DI, `dio` HTTP, `mocktail` tests, FVM.

**Spec:** `docs/superpowers/specs/2026-06-02-appconfig-apiclient-di-design.md`

**Invariant for every task:** after the final step, `fvm flutter test` is fully green, `fvm dart analyze` is clean. Commit only on green.

---

## File Structure

**Created:** none (design doc + this plan already exist).

**Modified — production:**
- `lib/infrastructure/config/environment.dart` — `AppConfig`, delete `ProfileConstants`/`_Config`
- `lib/infrastructure/http/api_client.dart` — static → instance (+ temporary facade, later removed)
- `lib/infrastructure/http/interceptors/mock_interceptor.dart` — `appConfig` ctor param
- `lib/app/bootstrap/app_bootstrap.dart` — build `AppConfig`, drop `ApiClient` statics (final state)
- `lib/app/bootstrap/app_session_listeners.dart`, `lib/app/app.dart`, `lib/app/session/session_cubit.dart`, `lib/app/dev_console/tabs/environment_tab.dart`, `lib/infrastructure/analytics/sentry_analytics_service.dart` — read `AppConfig` (Task 1)
- `lib/app/di/app_dependencies.dart`, `lib/app/di/app_scope.dart` — `createApiClient` + repo factories + providers
- 6 repos: `lib/features/users/data/repositories/{user_repository,authority_repository}.dart`, `lib/features/account/data/repositories/account_repository.dart`, `lib/features/auth/data/repositories/auth_repository_impl.dart`, `lib/features/lifecycle/data/repositories/lifecycle_repository.dart`, `lib/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart`
- `lib/features/dashboard/application/dashboard_cubit.dart`, `lib/features/dashboard/presentation/pages/dashboard_home_page.dart`

**Modified — tests:** `test/test_utils.dart`, `test/infrastructure/config/environment_test.dart`, `test/infrastructure/http/api_client_test.dart`, `test/app/session/session_cubit_test.dart`, plus ~30 files constructing concrete repos (enumerated per migrate task via grep).

---

## Task 1: Introduce `AppConfig`, delete `ProfileConstants` (behavior parity ≈ #145)

**Files:**
- Modify: `lib/infrastructure/config/environment.dart`
- Modify: `lib/infrastructure/http/api_client.dart` (temporary `static AppConfig _appConfig` + setter — removed in Task 5)
- Modify: `lib/infrastructure/http/interceptors/mock_interceptor.dart`
- Modify: `lib/app/app.dart`, `lib/app/bootstrap/app_bootstrap.dart`, `lib/app/bootstrap/app_session_listeners.dart`, `lib/app/session/session_cubit.dart`, `lib/app/dev_console/tabs/environment_tab.dart`, `lib/app/di/app_dependencies.dart`, `lib/app/di/app_scope.dart`, `lib/infrastructure/analytics/sentry_analytics_service.dart`, `lib/features/dashboard/presentation/pages/dashboard_home_page.dart`
- Test: `test/infrastructure/config/environment_test.dart`, `test/app/session/session_cubit_test.dart`, `test/test_utils.dart`

- [ ] **Step 1: Write the failing `AppConfig` test**

Replace the body of `test/infrastructure/config/environment_test.dart`'s first group with:

```dart
group('AppConfig', () {
  test('dev config sets development environment', () {
    const config = AppConfig.dev();
    expect(config.isDevelopment, true);
    expect(config.apiBaseUrl, isNull);
  });
  test('test config sets test environment', () {
    const config = AppConfig.test();
    expect(config.isDevelopment, false);
    expect(config.isProduction, false);
    expect(config.apiBaseUrl, isNull);
  });
  test('prod config sets production environment', () {
    const config = AppConfig.prod();
    expect(config.isProduction, true);
    expect(config.apiBaseUrl, TemplateConfig.prodApiUrl);
  });
  test('fromEnvironment maps each enum value', () {
    expect(AppConfig.fromEnvironment(Environment.dev).isDevelopment, true);
    expect(AppConfig.fromEnvironment(Environment.test).isTest, true);
    expect(AppConfig.fromEnvironment(Environment.prod).isProduction, true);
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `fvm flutter test test/infrastructure/config/environment_test.dart`
Expected: FAIL — `AppConfig` undefined.

- [ ] **Step 3: Replace `ProfileConstants` with `AppConfig` in `environment.dart`**

Replace the entire `ProfileConstants` class and the `_Config` class with:

```dart
final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.certificatePins,
    required this.idleTimeout,
  });

  const AppConfig.dev()
    : environment = Environment.dev,
      apiBaseUrl = null,
      certificatePins = const <String>[],
      idleTimeout = null;

  const AppConfig.test()
    : environment = Environment.test,
      apiBaseUrl = null,
      certificatePins = const <String>[],
      idleTimeout = null;

  const AppConfig.prod()
    : environment = Environment.prod,
      apiBaseUrl = TemplateConfig.prodApiUrl,
      certificatePins = const <String>[],
      idleTimeout = const Duration(minutes: 15);

  factory AppConfig.fromEnvironment(Environment environment) => switch (environment) {
    Environment.dev => const AppConfig.dev(),
    Environment.prod => const AppConfig.prod(),
    Environment.test => const AppConfig.test(),
  };

  final Environment environment;
  final String? apiBaseUrl;
  final List<String> certificatePins;
  final Duration? idleTimeout;

  bool get isProduction => environment == Environment.prod;
  bool get isDevelopment => environment == Environment.dev;
  bool get isTest => environment == Environment.test;

  /// Production-only DSN passed via `--dart-define=SENTRY_DSN=...`.
  /// Returns null in non-prod, or when the define is absent / empty.
  /// **Never** commit a DSN to source (public template).
  String? get sentryDsn {
    if (!isProduction) return null;
    const dsn = String.fromEnvironment('SENTRY_DSN');
    return dsn.isEmpty ? null : dsn;
  }
}
```

Keep `enum Environment { dev, prod, test }` and the `template_config.dart` import.

- [ ] **Step 4: Add a TEMPORARY static config to `ApiClient` so it still compiles**

In `lib/infrastructure/http/api_client.dart`, add a temporary static (this is migration scaffolding, deleted in Task 5):

```dart
  static AppConfig _appConfig = const AppConfig.dev();
  static AppConfig get appConfig => _appConfig;
  static set appConfig(AppConfig value) {
    _appConfig = value;
    _dio?.close();
    _dio = null;
    _interceptorChainSnapshot = const [];
  }
```

Replace inside the existing static methods: `ProfileConstants.isProduction` → `_appConfig.isProduction`; `(ProfileConstants.api as String)` in `baseUrl` → `_appConfig.apiBaseUrl ?? ''`; `ProfileConstants.certificatePins` → `_appConfig.certificatePins`; `!ProfileConstants.isProduction` → `!_appConfig.isProduction`; pass `MockInterceptor(appConfig: _appConfig)`. In `reset()` add `appConfig = const AppConfig.dev();`.

- [ ] **Step 5: Migrate the remaining `ProfileConstants` consumers to `AppConfig`**

Apply these exact edits (identical to PR #145):

- `lib/infrastructure/http/interceptors/mock_interceptor.dart`: add `MockInterceptor({this.appConfig = const AppConfig.dev()});` + `final AppConfig appConfig;`; change `!ProfileConstants.isTest` → `!appConfig.isTest`.
- `lib/app/di/app_dependencies.dart`: `const AppDependencies({this.appConfig = const AppConfig.dev()});` + `final AppConfig appConfig;`; `createAnalyticsService` uses `appConfig.sentryDsn`.
- `lib/app/di/app_scope.dart`: add `RepositoryProvider<AppConfig>.value(value: dependencies.appConfig),` and `SessionCubit(secureStorage: context.read<ISecureStorage>(), appConfig: context.read<AppConfig>())..restore()`; import `environment.dart`.
- `lib/app/session/session_cubit.dart`: ctor `SessionCubit({ISecureStorage? secureStorage, this.appConfig = const AppConfig.dev()})`; `final AppConfig appConfig;`; `if (appConfig.isProduction)`.
- `lib/app/bootstrap/app_bootstrap.dart`: replace `ProfileConstants.setEnvironment(config.environment); final dependencies = AppDependencies(environment: config.environment);` with `final appConfig = AppConfig.fromEnvironment(config.environment); final dependencies = AppDependencies(appConfig: appConfig); ApiClient.appConfig = appConfig;`; `sentryActive`/`dsn` use `appConfig.sentryDsn`.
- `lib/app/app.dart`: `if (context.read<AppConfig>().sentryDsn != null) SentryNavigatorObserver(),`.
- `lib/app/bootstrap/app_session_listeners.dart`: `widget.idleTimeoutOverride ?? context.read<AppConfig>().idleTimeout`.
- `lib/app/dev_console/tabs/environment_tab.dart`: `_buildEnvironmentInfo(context.read<AppConfig>())`; signature `Map<String,String> _buildEnvironmentInfo(AppConfig appConfig)`; `'Environment': appConfig.isProduction ? 'Production' : (appConfig.isTest ? 'Test' : 'Development')`; `'API Endpoint': appConfig.apiBaseUrl ?? 'Mock'`; import `flutter_bloc`.
- `lib/features/dashboard/presentation/pages/dashboard_home_page.dart`: `final environment = switch (context.read<AppConfig>().environment) { Environment.prod => 'prod', Environment.dev => 'dev', Environment.test => 'test' };`.
- `lib/infrastructure/analytics/sentry_analytics_service.dart`: doc comment `ProfileConstants.sentryDsn` → `AppConfig.sentryDsn`.

- [ ] **Step 6: Update tests that mutated the old global**

- `test/test_utils.dart`: replace both `ProfileConstants.setEnvironment(Environment.test);` with `ApiClient.appConfig = const AppConfig.test();` (in `setupUnitTest` and `setupRepositoryUnitTest`).
- `test/app/session/session_cubit_test.dart`: delete the `setUp`/`tearDown` `ProfileConstants.setEnvironment(...)` lines; in the expired-prod test `build:` use `SessionCubit(secureStorage: secure, appConfig: const AppConfig.prod())`.

- [ ] **Step 7: Run analyze + full suite**

Run: `fvm dart analyze && fvm flutter test`
Expected: analyze clean; all tests pass (behavior parity with #145).

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "$(printf 'refactor(#144): introduce immutable AppConfig, remove ProfileConstants\n\nReplaces the global ProfileConstants map with a typed final AppConfig.\nApiClient temporarily keeps a static appConfig (removed once it becomes\ninstance-injected). Behavior parity with the test suite.\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

## Task 2 (EXPAND): Add instance API to `ApiClient` + DI provider + test helper, keep static facade

Goal: `ApiClient` gains a full instance API while the existing static API keeps working by delegating to a single lazily-built default instance. Nothing else changes behavior. Suite stays green.

**Files:**
- Modify: `lib/infrastructure/http/api_client.dart`
- Modify: `lib/app/di/app_dependencies.dart`, `lib/app/di/app_scope.dart`
- Modify: `test/test_utils.dart`
- Test: `test/infrastructure/http/api_client_test.dart`

- [ ] **Step 1: Write a failing instance-API test**

Add to `test/infrastructure/http/api_client_test.dart`:

```dart
group('ApiClient instance API', () {
  test('instance get goes through MockInterceptor in test config', () async {
    final client = ApiClient(appConfig: const AppConfig.test(), secureStorage: FlutterSecureStorageAdapter());
    final res = await client.get('/admin/users', pathParams: 'user-1');
    expect(res.statusCode, 200);
  });

  test('interceptorChainSnapshot is per-instance and unmodifiable', () {
    final client = ApiClient(appConfig: const AppConfig.test(), secureStorage: FlutterSecureStorageAdapter());
    client.instance; // build dio
    expect(client.interceptorChainSnapshot, isNotEmpty);
    expect(() => client.interceptorChainSnapshot.add(
      const InterceptorChainEntry(name: 'X', detail: 'X')), throwsUnsupportedError);
  });

  test('injected dio is used as-is (test seam)', () {
    final testDio = Dio(BaseOptions(baseUrl: 'https://x', responseType: ResponseType.plain));
    final client = ApiClient(appConfig: const AppConfig.prod(), dio: testDio);
    expect(identical(client.instance, testDio), true);
  });
});
```

Ensure imports: `package:dio/dio.dart`, `environment.dart`, `secure_storage.dart`.

- [ ] **Step 2: Run it to verify it fails**

Run: `fvm flutter test test/infrastructure/http/api_client_test.dart -p vm`
Expected: FAIL — `ApiClient` has no generative constructor / `client.get` not defined.

- [ ] **Step 3: Convert the body of `ApiClient` to instance, with a delegating static facade**

Rewrite `lib/infrastructure/http/api_client.dart` so the class holds instance state and the statics delegate. Target shape:

```dart
class ApiClient {
  ApiClient({
    required this.appConfig,
    ISecureStorage? secureStorage,
    this.onSessionExpired,
    Dio? dio,
  }) : _secureStorage = secureStorage,
       _dio = dio;

  static final _log = AppLogger.getLogger('ApiClient');
  static const int _timeoutSeconds = 30;

  final AppConfig appConfig;
  final OnSessionExpired? onSessionExpired;
  final ISecureStorage? _secureStorage;
  Dio? _dio;
  List<InterceptorChainEntry> _chainSnapshot = const [];

  Dio get instance => _dio ??= _createDio();
  List<InterceptorChainEntry> get interceptorChainSnapshot => List.unmodifiable(_chainSnapshot);

  Future<Response<String>> get(String path, {String? pathParams, Map<String, dynamic>? queryParams}) async {
    final fullPath = pathParams != null ? '$path/$pathParams' : path;
    try {
      return await instance.get<String>(fullPath, queryParameters: queryParams,
        options: Options(extra: {'_basePath': path, '_pathParams': pathParams, '_queryParams': queryParams}));
    } on DioException catch (e) { throw _mapDioException(e); }
  }
  // post/put/patch/delete: copy the existing bodies verbatim, drop `static`, call `instance.<verb>`.

  Dio _createDio() {
    _log.debug('Creating Dio instance (production: {})', [appConfig.isProduction]);
    if (_secureStorage == null) {
      _log.warn('ApiClient.secureStorage is null at Dio creation — interceptors will fall back '
        'to a private FlutterSecureStorageAdapter and diverge from the repository layer.');
    }
    final dio = Dio(BaseOptions(
      baseUrl: appConfig.apiBaseUrl ?? '',
      connectTimeout: const Duration(seconds: _timeoutSeconds),
      receiveTimeout: const Duration(seconds: _timeoutSeconds),
      responseType: ResponseType.plain,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'}));
    final pins = appConfig.certificatePins;
    if (pins.isNotEmpty) { dio.httpClientAdapter = buildPinnedAdapter(pins); }
    final chain = <({Interceptor interceptor, InterceptorChainEntry meta})>[
      // …existing entries verbatim, but: AuthInterceptor(secureStorage: _secureStorage),
      // TokenRefreshInterceptor(dio: dio, onSessionExpired: onSessionExpired, secureStorage: _secureStorage),
      // if (!appConfig.isProduction) MockInterceptor(appConfig: appConfig) entry,
    ];
    dio.interceptors.addAll(chain.map((e) => e.interceptor));
    _chainSnapshot = chain.map((e) => e.meta).toList(growable: false);
    return dio;
  }

  // Pure static utilities — UNCHANGED (no global state):
  static String decodeUTF8(String toEncode) { /* existing body */ }
  static dynamic _serializeData<T>(T data) { /* existing body */ }
  static AppException _mapDioException(DioException e) { /* existing body */ }
  static AppException _mapBadResponse(DioException e) { /* existing body */ }
  static AppException _mapUnknown(DioException e) { /* existing body */ }

  // ---- TEMPORARY static facade (removed in Task 5) ----
  static ApiClient? _default;
  static AppConfig _staticConfig = const AppConfig.dev();
  static ISecureStorage? secureStorage;        // set by bootstrap/tests during migration
  static OnSessionExpired? onSessionExpired_;   // unused dormant; kept for parity
  static ApiClient get _facade => _default ??=
      ApiClient(appConfig: _staticConfig, secureStorage: secureStorage);
  static set appConfig(AppConfig v) { _staticConfig = v; _default = null; }
  static AppConfig get appConfig => _staticConfig;
  static Dio? _testDio;
  static void setTestInstance(Dio dio) { _testDio = dio; _default = ApiClient(appConfig: _staticConfig, secureStorage: secureStorage, dio: dio); }
  static void resetTestInstance() { _testDio = null; _default = null; }
  static void reset() { _default = null; _testDio = null; secureStorage = null; _staticConfig = const AppConfig.dev(); }
  static List<InterceptorChainEntry> get interceptorChainSnapshotStatic => _facade.interceptorChainSnapshot;
}
```

Notes for the implementer:
- The five static facade convenience methods (`static Future<Response<String>> get/post/put/patch/delete`) must remain too — each one-liner delegates: `static Future<Response<String>> get(...) => _facade.get(...);`. (Define instance methods first, then the static delegators with distinct internal routing — simplest is to keep the static delegators calling `_facade.<verb>`.)
- Keep the existing static `interceptorChainSnapshot` getter name working by pointing it at `_facade.interceptorChainSnapshot` (so `dashboard_cubit` and `api_client_test` snapshot group stay green until migrated).

> This facade is deliberately ugly and temporary. Task 5 deletes every `static` member below the pure utilities.

- [ ] **Step 4: Add `createApiClient` + repo-factory params (signatures only) and the DI provider**

`lib/app/di/app_dependencies.dart` — add:

```dart
ApiClient createApiClient(ISecureStorage secureStorage) =>
    ApiClient(appConfig: appConfig, secureStorage: secureStorage);
```
(Import `api_client.dart`. Do NOT yet change the repo-factory signatures — that happens per migrate task.)

`lib/app/di/app_scope.dart` — add the provider immediately AFTER the `RepositoryProvider<ISecureStorage>` block and BEFORE the repos:

```dart
RepositoryProvider<ApiClient>(create: (context) => dependencies.createApiClient(context.read<ISecureStorage>())),
```
(Import `api_client.dart`.)

- [ ] **Step 5: Add the test helper**

`test/test_utils.dart` — add inside `class TestUtils`:

```dart
/// Mock-backed client for tests: test AppConfig → MockInterceptor serves
/// assets/mock/*.json; shared secure adapter → same MethodChannel mock the
/// repo layer reads. Pass [dio] to inject a stub.
static ApiClient apiClient({Dio? dio}) => ApiClient(
    appConfig: const AppConfig.test(),
    secureStorage: FlutterSecureStorageAdapter(),
    dio: dio);
```
(Import `package:dio/dio.dart`.)

- [ ] **Step 6: Run analyze + full suite**

Run: `fvm dart analyze && fvm flutter test`
Expected: analyze clean; all tests pass (static callers untouched, new instance tests pass).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "$(printf 'refactor(#144): add instance ApiClient API + DI provider (expand phase)\n\nApiClient gains a full instance API and a single-instance RepositoryProvider.\nA temporary static facade delegates to one default instance so existing\nstatic callers keep working while repos migrate. TestUtils.apiClient() added.\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

## Task 3 (MIGRATE): Convert repositories to the injected instance, one feature per commit

For EACH repository below, the recipe is identical. **Repeat all steps per sub-task.**

### Generic recipe (apply per repo)

1. **Repo file** — add constructor + field, replace static calls:
   - 5 default-ctor repos (`UserRepository`, `AuthorityRepositoryImpl`, `AccountRepository`, `LifecycleRepository`, `DynamicFormRepository`): add as the first member
     ```dart
     <ClassName>(this._apiClient);
     final ApiClient _apiClient;
     ```
   - In that file replace every `ApiClient.get(` → `_apiClient.get(` (and `.post(`/`.put(`/`.patch(`/`.delete(`). Leave `ApiClient.decodeUTF8(` unchanged (pure static util).
2. **DI factory** — `app_dependencies.dart`: change the factory to take `ApiClient`:
   `I<X>Repository create<X>Repository(ApiClient api) => <X>Repository(api);`
3. **DI provider** — `app_scope.dart`: change the repo provider to thread it:
   `create: (context) => dependencies.create<X>Repository(context.read<ApiClient>())`.
4. **Tests** — find every concrete construction and inject the helper:
   - Run: `grep -rln "<ClassName>(" test/`
   - In each hit, replace `<ClassName>()` → `<ClassName>(TestUtils.apiClient())`. If the test imports `dio`/uses `setTestInstance`, pass `TestUtils.apiClient(dio: testDio)` and delete the `ApiClient.setTestInstance(...)` line. Remove now-redundant `ApiClient.reset()` only if the file no longer references any other static (otherwise leave until Task 5).
5. Run: `fvm flutter test` → green. Commit `refactor(#144): inject ApiClient into <X>Repository`.

### Task 3a: UserRepository

- [ ] Repo: `lib/features/users/data/repositories/user_repository.dart` — add `UserRepository(this._apiClient); final ApiClient _apiClient;`; replace `ApiClient.<verb>(` → `_apiClient.<verb>(`.
- [ ] DI: `app_dependencies.dart` → `IUserRepository createUserRepository(ApiClient api) => UserRepository(api);`
- [ ] DI: `app_scope.dart` → `RepositoryProvider<IUserRepository>(create: (context) => dependencies.createUserRepository(context.read<ApiClient>()))`.
- [ ] Tests: `grep -rln "UserRepository(" test/` → in each, `UserRepository()` → `UserRepository(TestUtils.apiClient())`. (Known: `test/features/users/data/repositories/user_repository_test.dart`, `.../application/user_list_bloc_test.dart`, `.../user_editor_bloc_test.dart`, `.../presentation/pages/user_editor_screen_test.dart`, `.../application/usecases/{fetch_user,delete_user,save_user,search_users}_usecase_test.dart`, `test/app/di/repository_contracts_test.dart`.)
- [ ] Run `fvm flutter test`; expected green. Commit.

### Task 3b: AuthorityRepositoryImpl

- [ ] Repo: `lib/features/users/data/repositories/authority_repository.dart` — add ctor/field; replace verbs.
- [ ] DI: `createAuthorityRepository(ApiClient api) => AuthorityRepositoryImpl(api);` + provider reads `context.read<ApiClient>()`.
- [ ] Tests: `grep -rln "AuthorityRepositoryImpl(" test/` → inject helper. (Known: `.../data/repositories/authority_reporitory_test.dart`, `.../application/authority_bloc_test.dart`, `.../application/usecases/list_authorities_usecase_test.dart`, `repository_contracts_test.dart`.)
- [ ] Run `fvm flutter test`; green. Commit.

### Task 3c: AccountRepository

- [ ] Repo: `lib/features/account/data/repositories/account_repository.dart` — add ctor/field; replace `ApiClient.<verb>(` → `_apiClient.<verb>(`; **keep** `ApiClient.decodeUTF8(...)` static.
- [ ] DI: `createAccountRepository(ApiClient api) => AccountRepository(api);` + provider reads `context.read<ApiClient>()`.
- [ ] Tests: `grep -rln "AccountRepository(" test/` → inject helper. (Known: `.../data/repositories/account_repository_test.dart`, `.../application/account_bloc_test.dart`, `.../application/usecases/{register_account,reset_password,get_account,update_account,change_password}_usecase_test.dart`, `register_bloc_test.dart`, `change_password_bloc_test.dart`, `forgot_password_bloc_test.dart`, `repository_contracts_test.dart`.)
- [ ] Run `fvm flutter test`; green. Commit.

### Task 3d: LoginRepository (auth) — has an existing constructor

- [ ] Repo: `lib/features/auth/data/repositories/auth_repository_impl.dart` — extend the ctor to require `apiClient`:
  ```dart
  LoginRepository({required ApiClient apiClient, ISecureStorage? secureStorage, IAuthSessionRepository? sessionRepository})
      : _apiClient = apiClient,
        _sessionRepository = sessionRepository ?? AuthSessionRepository(secureStorage: secureStorage ?? FlutterSecureStorageAdapter());
  final ApiClient _apiClient;
  ```
  (Preserve the existing `_sessionRepository` init exactly; only add `_apiClient`.) Replace `ApiClient.<verb>(` → `_apiClient.<verb>(`.
- [ ] DI: `app_dependencies.dart` → `IAuthRepository createAuthRepository(ISecureStorage secureStorage, ApiClient api) => LoginRepository(secureStorage: secureStorage, apiClient: api);`
- [ ] DI: `app_scope.dart` → `RepositoryProvider<IAuthRepository>(create: (context) => dependencies.createAuthRepository(context.read<ISecureStorage>(), context.read<ApiClient>()))`.
- [ ] Tests: `grep -rln "LoginRepository(" test/` → add `apiClient: TestUtils.apiClient()` to each construction (keep existing named args). (Known: `.../auth/data/repositories/login_repository_test.dart`, `login_bloc_test.dart`, `.../application/usecases/{authenticate_user,send_otp,verify_otp,logout,persist_auth_session}_usecase_test.dart` — verify with grep; some use `MockAuthRepository` and are unaffected.)
- [ ] Run `fvm flutter test`; green. Commit.

### Task 3e: DynamicFormRepository

- [ ] Repo: `lib/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart` — add ctor/field; replace verbs.
- [ ] DI: `createDynamicFormRepository(ApiClient api) => DynamicFormRepository(api);` + provider reads `context.read<ApiClient>()`.
- [ ] Tests: these use `ApiClient.setTestInstance(testDio)` — switch to the `dio:` seam:
  - `test/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl_test.dart`: replace `ApiClient.setTestInstance(testDio);` + `DynamicFormRepository()` with `final repo = DynamicFormRepository(TestUtils.apiClient(dio: testDio));`; delete the `ApiClient.reset()` line if no other static remains.
  - `test/shared/dynamic_forms/application/dynamic_form_bloc_test.dart`: same — build the repo (or whatever the bloc consumes) with `TestUtils.apiClient(dio: testDio)`; delete `setTestInstance`/`reset` lines that are now dead.
- [ ] Run `fvm flutter test`; green. Commit.

### Task 3f: LifecycleRepository (file-only — no wiring, no test)

- [ ] Repo: `lib/features/lifecycle/data/repositories/lifecycle_repository.dart` — add `LifecycleRepository(this._apiClient); final ApiClient _apiClient;`; replace `ApiClient.get(` → `_apiClient.get(`.
- [ ] Verify no production/test construction: `grep -rn "LifecycleRepository(" lib/ test/` → expect only the class definition (tests use `MockLifecycleRepository`). No DI/test edits.
- [ ] Run `fvm flutter test`; green. Commit `refactor(#144): inject ApiClient into LifecycleRepository`.

---

## Task 4 (MIGRATE): Dashboard cubit reads instance snapshot + fix Finding #3 guard

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_cubit.dart`
- Modify: `lib/app/di/app_scope.dart`
- Modify: `lib/features/dashboard/presentation/pages/dashboard_home_page.dart`
- Test: `test/features/dashboard/application/dashboard_cubit_test.dart`

- [ ] **Step 1: Inject `ApiClient` into `SystemDashboardCubit`**

`dashboard_cubit.dart`: add `required ApiClient apiClient` to the constructor and a `final ApiClient _apiClient;` field; replace `final snapshot = ApiClient.interceptorChainSnapshot;` → `final snapshot = _apiClient.interceptorChainSnapshot;`. Import `api_client.dart`.

- [ ] **Step 2: Wire it in `app_scope.dart`**

In the `SystemDashboardCubit` provider add `apiClient: context.read<ApiClient>(),` to the existing named args.

- [ ] **Step 3: Fix Finding #3 — guard the `AppConfig` read in `dashboard_home_page.dart`**

In `_updateAppConfigFromLifecycle`, the `context.read<AppConfig>()` must not throw when the provider is absent (consistent with the sibling `LifecycleBloc` try/catch). Replace the `switch` block with a guarded read:

```dart
AppConfig? appConfig;
try {
  appConfig = context.read<AppConfig>();
} catch (_) {
  // AppConfig not provided (standalone/partial-DI pump) — fall back to dev label.
}
final environment = switch (appConfig?.environment) {
  Environment.prod => 'prod',
  Environment.test => 'test',
  Environment.dev || null => 'dev',
};
```

- [ ] **Step 4: Update `dashboard_cubit_test.dart` construction**

`grep -n "SystemDashboardCubit(" test/features/dashboard/application/dashboard_cubit_test.dart` → add `apiClient: TestUtils.apiClient(),` to the named args. (`dashboard_page_test.dart` uses `MockSystemDashboardCubit` — unaffected.)

- [ ] **Step 5: Run analyze + full suite**

Run: `fvm dart analyze && fvm flutter test`
Expected: clean + green.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "$(printf 'refactor(#144): inject ApiClient into SystemDashboardCubit; guard dashboard AppConfig read\n\nDashboard reads interceptorChainSnapshot from the injected instance.\nGuards context.read<AppConfig>() to match the sibling LifecycleBloc\nfallback (review finding #3).\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

## Task 5 (CONTRACT): Delete the static facade, all static config, and the `reset()` ceremony

At this point `grep -rn "ApiClient\.\(get\|post\|put\|patch\|delete\|instance\|appConfig\|secureStorage\|setTestInstance\|reset\|interceptorChainSnapshot\)" lib/` should show NO production callers (only the class definition). Verify before deleting.

**Files:**
- Modify: `lib/infrastructure/http/api_client.dart`, `lib/app/bootstrap/app_bootstrap.dart`
- Test: `test/infrastructure/http/api_client_test.dart`, `test/test_utils.dart`

- [ ] **Step 1: Verify no static callers remain**

Run: `grep -rn "ApiClient\.\(get\|post\|put\|patch\|delete\|instance\|appConfig\|secureStorage\|onSessionExpired\|setTestInstance\|resetTestInstance\|reset\|interceptorChainSnapshot\)" lib/`
Expected: empty (the only `ApiClient.` left in lib is `ApiClient.decodeUTF8` in `account_repository.dart`, which is fine).

- [ ] **Step 2: Delete the temporary static facade from `api_client.dart`**

Remove: `_default`, `_staticConfig`, `static secureStorage`, `onSessionExpired_`, `_facade`, `static set/get appConfig`, `_testDio`, `setTestInstance`, `resetTestInstance`, `reset`, the static `get/post/put/patch/delete` delegators, and the static `interceptorChainSnapshot`/`interceptorChainSnapshotStatic`. Keep ONLY: the generative constructor, instance fields/getters/methods, `InterceptorChainEntry`, and the pure `static` utilities (`decodeUTF8`, `_serializeData`, `_mapDioException`, `_mapBadResponse`, `_mapUnknown`).

- [ ] **Step 3: Clean `app_bootstrap.dart`**

Delete the `ApiClient.appConfig = appConfig;` line and any `ApiClient.secureStorage = ...;`/`ApiClient.onSessionExpired = ...;` assignments. The shared `secureStorage` already flows to `ApiClient` via `AppScope` → `createApiClient`. Confirm `appConfig` is still built (`AppConfig.fromEnvironment`) and passed to `AppDependencies`.

- [ ] **Step 4: Rewrite `api_client_test.dart` to pure instance form**

Remove every `ApiClient.reset()`, `ApiClient.setTestInstance(...)`, `ApiClient.appConfig = ...`. Each test builds its own client: prod-stub group → `ApiClient(appConfig: const AppConfig.prod(), dio: testDio)`; mock group → `ApiClient(appConfig: const AppConfig.test(), secureStorage: FlutterSecureStorageAdapter())`; `decodeUTF8` group stays `ApiClient.decodeUTF8(...)` (static util); snapshot group uses a fresh `client.interceptorChainSnapshot`. No global teardown needed.

- [ ] **Step 5: Clean `test_utils.dart`**

Delete `ApiClient.appConfig = const AppConfig.test();` (both setups), `ApiClient.secureStorage = FlutterSecureStorageAdapter();` (both setups + teardown), and `ApiClient.reset();` in `tearDownUnitTest`. Keep `TestUtils.apiClient()`, the secure-storage MethodChannel mock, and `_clearStorage`. (The MethodChannel mock + `_clearStorage` remain the isolation mechanism; per-instance clients remove the need for `ApiClient.reset`.)

- [ ] **Step 6: Run analyze + full suite + zero-globals check**

Run: `fvm dart analyze && fvm flutter test`
Then: `grep -rn "static " lib/infrastructure/http/api_client.dart` → only the logger, `_timeoutSeconds`, and the pure utility functions should remain (no mutable static state).
Expected: clean + all green.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "$(printf 'refactor(#144): remove static ApiClient facade and all global config (contract phase)\n\nApiClient is now instance-only, injected via DI. Deletes the static\nfacade, static config/secureStorage, setTestInstance, and reset().\nbootstrap no longer mutates ApiClient statics. Zero mutable global state\nin the config + HTTP layer.\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

## Task 6: Final gates, format, PR, close #145

- [ ] **Step 1: Format**

Run: `fvm dart format . --line-length=120`
If anything reformats: `git add -A && git commit -m "style: dart format"`.

- [ ] **Step 2: Full verification**

Run: `fvm dart analyze && fvm flutter test`
Expected: analyze clean; all tests pass (target: same count as baseline, 1543+). Record the exact pass count from the output.

- [ ] **Step 3: Push**

Run: `git push -u origin feat/144-appconfig-apiclient-di`

- [ ] **Step 4: Open the PR**

```bash
gh pr create --repo cevheri/flutter-bloc-advanced --base main \
  --title "feat(#144): immutable AppConfig + DI-injected ApiClient (no global state)" \
  --body "$(printf 'Closes #144. Supersedes #145.\n\n## What\n- Replace global ProfileConstants map with immutable, typed AppConfig (kept from #145).\n- Convert static ApiClient to an instance injected through the existing RepositoryProvider DI spine.\n- 6 HTTP repositories receive ApiClient via constructor; one shared instance built in AppDependencies.\n- SystemDashboardCubit reads interceptorChainSnapshot from the injected instance.\n- Delete ApiClient.reset()/setTestInstance and all static config — test isolation is now structural.\n\n## Scope note (honest)\nIssue #144 asked for config DI. This PR also removes the *last* global by making ApiClient instance-injected (the review of #145 found ApiClient still held mutable global config). AuthSessionRepository/MenuRepository are untouched (no HTTP).\n\n## Review findings folded in\n- #2 dual source of truth: eliminated — one AppConfig, one ApiClient via DI.\n- #3 unguarded dashboard context.read<AppConfig>(): now guarded like the sibling LifecycleBloc read.\n\n## Verification\n- fvm dart analyze: clean\n- fvm flutter test: all green\n- fvm dart format --line-length=120: clean\n\nDesign + plan: docs/superpowers/specs and docs/superpowers/plans.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)')"
```

- [ ] **Step 5: Close #145 as superseded**

```bash
gh pr comment 145 --repo cevheri/flutter-bloc-advanced --body "Superseded by the new PR for #144, which keeps this AppConfig design and additionally removes the last global by making ApiClient instance-injected via DI. Closing as superseded."
gh pr close 145 --repo cevheri/flutter-bloc-advanced
```

---

## Self-Review (completed during authoring)

- **Spec coverage:** §3.1 AppConfig→T1; §3.2 ApiClient instance→T2/T5; §3.3 repos→T3a–f; §3.4 DI→T2/T3/T4; §3.5 bootstrap→T1/T5; §3.6 finding #2→T5 (single source), finding #3→T4; §4 tests→T1–T5; §5 sequence→task order. All covered.
- **Placeholder scan:** repo/test edits use exact paths + grep + explicit transforms; per-repo code shown. No TBD/TODO.
- **Type consistency:** `ApiClient({required appConfig, secureStorage, onSessionExpired, dio})`, `_apiClient` field name, `createApiClient(ISecureStorage)`, `create<X>Repository(ApiClient)`, `TestUtils.apiClient({Dio? dio})`, `interceptorChainSnapshot` instance getter — consistent across tasks.
- **Green invariant:** expand-migrate-contract keeps the full suite green at every commit; static facade removed only after all callers migrate (verified by grep in T5/S1).
