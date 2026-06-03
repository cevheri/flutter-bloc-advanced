# Testing Architecture

This document explains how tests are structured, bootstrapped, and written in
this template. If you are new to the project, read this before adding tests.

For the HTTP **mock data** layer (how `assets/mock/*.json` is served to the app
at dev/test time), see [`mock-architecture.md`](mock-architecture.md). This
document is about the **test suite** itself.

---

## Philosophy

- **Mirror the source tree.** `test/` mirrors `lib/` one-to-one, so the test for
  any file is exactly where you'd expect it.
- **Mock at the boundary, not the wire.** Unit and BLoC tests mock the
  repository/use-case interface with `mocktail`. They do not go through HTTP or
  the mock interceptor.
- **One global bootstrap.** Cross-cutting setup (binding init, logger, fallback
  registration, per-test environment reset) lives in one place, not in every
  file. Test files contain only what is unique to them.
- **Sealed states, exhaustive matching.** BLoC tests assert on sealed state
  variants (see `CLAUDE.md` → State Modeling).
- **Determinism.** Tests must not depend on wall-clock time, ordering, or
  leaked state between tests.

---

## Test stack

| Tool | Purpose |
| --- | --- |
| `flutter_test` | Test runner, `WidgetTester`, matchers |
| `bloc_test` | `blocTest(...)` + `MockBloc` for BLoC/Cubit state assertions |
| `mocktail` | Mocks/fakes without code generation (`Mock`, `Fake`, `when`, `verify`, `any`) |
| `fake_async` | Virtual time for timer/timeout logic |
| `integration_test` | (declared) on-device end-to-end harness |

No `mockito`, no `build_runner` for mocks — `mocktail` is the single mocking
library.

---

## Directory layout

`test/` mirrors `lib/`:

```
test/
├── flutter_test_config.dart   # GLOBAL bootstrap (auto-discovered by flutter test)
├── support/
│   └── test_env.dart          # TestEnv: reset(), authenticate(), apiClient(), autoReset
├── mocks/
│   ├── mock_classes.dart      # Mock*/Fake* classes + registerAllFallbackValues()
│   └── fake_data.dart         # Shared fixtures (mockUserFullPayload, ...)
├── architecture/              # Meta-tests enforcing rules (see below)
│   ├── import_guard_test.dart        # layer dependency rules
│   └── test_file_naming_test.dart    # forbids *.test.dart (dot) files
├── app/                       # app/ layer tests (router, shell, theme, di, ...)
├── core/                      # core/ tests (errors, logging, security, result, ...)
├── features/<feature>/        # application/ data/ domain/ navigation/ presentation/
├── infrastructure/            # config, http (+ interceptors), storage, cache, ...
├── shared/                    # design_system, dynamic_forms, models, utils, widgets
└── main/                      # app_test.dart (root widget smoke test)
```

---

## The global bootstrap

`flutter test` automatically discovers `test/flutter_test_config.dart` and wraps
**every** test under `test/` with its `testExecutable`. This is where all
cross-cutting setup lives:

```dart
// test/flutter_test_config.dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // One-time per isolate.
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  EquatableConfig.stringify = true;
  registerAllFallbackValues();

  // Per-test, unless a file opts out.
  setUp(() async { if (TestEnv.autoReset) await TestEnv.reset(); });
  tearDown(() async { if (TestEnv.autoReset) await TestEnv.reset(); });

  await testMain();
}
```

**What this means for you:** a normal test file needs **no** manual setup for
storage, router, secure-storage, fallback registration, or logging. Just write
the test. The environment is clean before and after every test.

### `TestEnv` (`test/support/test_env.dart`)

A static helper — the single test-support entry point:

| Member | Use |
| --- | --- |
| `TestEnv.reset()` | Re-installs the secure-storage mock, clears all storage, seeds language `en`, selects the goRouter strategy. Called automatically by the bootstrap. |
| `TestEnv.authenticate()` | Seeds a mock JWT. Call in `setUp` or a test body — **never** in `setUpAll`. |
| `TestEnv.apiClient({Dio? dio})` | Builds a mock-backed `ApiClient` (test `AppConfig`, shared secure adapter). Pass a stub `dio` to control responses. |
| `TestEnv.autoReset` | Set `false` in a file's `setUpAll` to opt that file out of the global reset. |

> **Key facts that make this safe**
> - `flutter test` runs each file in its **own isolate**, so `TestEnv.autoReset`
>   is isolated per file — opting out in one file cannot affect another.
> - A file's `setUpAll` runs *after* the bootstrap body (which registers the
>   global `setUp`) but *before* the first test's `setUp`, so flipping
>   `autoReset` in `setUpAll` is observed by the global reset at runtime.
> - The global `setUp` clears the secure store before every test — that's why
>   `authenticate()` must run in `setUp`/test body, not `setUpAll`.

### Opting out (self-mocking files)

A file that installs its own `MethodChannel` or `SharedPreferences` mock should
opt out so the global reset doesn't trample it:

```dart
void main() {
  setUpAll(() => TestEnv.autoReset = false); // first thing in main()
  // ... file manages its own setUp/tearDown ...
}
```

Real example: `test/infrastructure/storage/local_storage_test.dart` installs a
`MockSharedPreferences` per group, so it opts out and resets explicitly.

---

## Writing each kind of test

### Use case tests — mock the repository interface

No HTTP, no bootstrap concerns. Pure `mocktail`:

```dart
import 'package:mocktail/mocktail.dart';
import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIUserRepository mockRepo;
  late SaveUserUseCase useCase;

  setUp(() {
    mockRepo = MockIUserRepository();
    useCase = SaveUserUseCase(mockRepo);
  });

  test('calls create when user has no id', () async {
    when(() => mockRepo.create(any())).thenAnswer((_) async => Success(newUser.copyWith(id: '2')));

    final result = await useCase.call(newUser);

    expect(result, isA<Success<UserEntity>>());
    verify(() => mockRepo.create(newUser)).called(1);
    verifyNever(() => mockRepo.update(any()));
  });
}
```

### BLoC / Cubit tests — `blocTest` + sealed states

Mock the use case (or repository), assert exact state transitions:

```dart
blocTest<UserListBloc, UserListState>(
  'emits [loading, loaded] when search succeeds',
  build: () {
    when(() => searchUsers(any())).thenAnswer((_) async => const Success(<UserEntity>[]));
    return UserListBloc(searchUsersUseCase: searchUsers, deleteUserUseCase: deleteUser);
  },
  act: (bloc) => bloc.add(const UserListSearch()),
  expect: () => [isA<UserListLoading>(), isA<UserListLoaded>()],
);
```

- Assert on sealed variants (`isA<UserListLoaded>()` or matching variant fields),
  not on a status enum.
- `MockBloc` (from `bloc_test`, declared in `mock_classes.dart`) is used by
  **widget** tests that need to feed a BLoC a scripted state stream.

### Repository tests

Repositories talk to `ApiClient`. In tests, build the client via
`TestEnv.apiClient()` (mock-backed by `assets/mock/*.json`) or inject a stub Dio
for failure paths.

### Widget tests — `MockBloc` + `TestEnv.authenticate`

```dart
testWidgets('renders dashboard when authenticated', (tester) async {
  TestEnv.authenticate();                 // in the test body, AFTER global reset
  await tester.pumpWidget(const App(language: 'en').buildHomeApp());
  await tester.pumpAndSettle();
  expect(find.byType(ResponsiveScaffold), findsOneWidget);
});
```

Provide BLoC state with a `MockBloc` so the UI renders deterministically without
real business logic.

### ApiClient tests — stub Dio at the wire

Inject a custom interceptor through the `dio` parameter to simulate transport
errors:

```dart
late _StubInterceptor stub;
late ApiClient client;

setUp(() {
  stub = _StubInterceptor();
  final testDio = Dio(BaseOptions(baseUrl: 'https://test.api', responseType: ResponseType.plain));
  testDio.interceptors.add(stub);
  client = ApiClient(appConfig: const AppConfig.prod(), dio: testDio);
});

test('maps 401 to UnauthorizedException', () async {
  stub.stubDioError(DioExceptionType.badResponse, statusCode: 401);
  expect(() => client.get('/endpoint'), throwsA(isA<UnauthorizedException>()));
});
```

`ApiClient` is constructed via dependency injection — there is no global
singleton or `setTestInstance`.

---

## Mocks and fakes

All shared doubles live in `test/mocks/`:

- **`mock_classes.dart`**
  - `Mock*` classes — repositories (concrete + interface), `MockBloc<E,S>` for
    each BLoC, `MockSharedPreferences`.
  - `Fake*` classes — fallback values for non-nullable `any()` arguments.
  - `registerAllFallbackValues()` — registers every fallback once; **called
    globally by the bootstrap**, so you do not call it per file.
- **`fake_data.dart`** — shared fixtures (`mockUserFullPayload`,
  `mockAuthorityPayload`, ...). Prefer these over building entities inline.

### Choosing a test double

Three categories — **reach for a mocktail mock first**; drop to a hand-fake only
for genuine stateful behavior; Dio handlers are always hand-written:

1. **mocktail mock (default)** — the `Mock*` classes in `mock_classes.dart`. Use
   for interface doubles where the test only configures return values
   (`when(...).thenReturn` / `thenAnswer`) and verifies calls (`verify`). This is
   the default for repository / use-case / BLoC doubles.
2. **hand-written fake** — a private `_Fake*` / `_Memory*` class next to the test,
   when the double needs real stateful or behavioral logic that mocktail makes
   awkward: in-memory stores, throw-on-Nth-call, selective/sequenced failures,
   return-driven branching (e.g. `_FakeUserRepository` in `user_list_bloc_test.dart`,
   `_MemorySecureStorage`). These are **purpose-built per test** — two same-named
   fakes in different files implement different surfaces and are *not* duplication;
   do not consolidate them into a shared "god" fake.
3. **Dio handler / interceptor stub** — a private `_Test*Handler` / `_StubInterceptor`
   extending Dio's `Interceptor` / `RequestInterceptorHandler` /
   `ResponseInterceptorHandler` / `ErrorInterceptorHandler`. Used to test
   interceptors at the Dio layer; they can't be mocked cleanly, and each records
   the signals its test asserts on.

---

## Architecture / guard tests

`test/architecture/` holds meta-tests that fail the build on rule violations:

- **`import_guard_test.dart`** enforces layer dependency rules
  (`core → nothing`, `shared → core`, `features → shared/infra/core`, no
  cross-feature internals). Known exceptions are listed explicitly and should
  shrink over time, not grow.
- **`test_file_naming_test.dart`** fails if any file is named `*.test.dart`
  (a dot instead of `_test.dart`) — such files compile and pass `analyze` but
  are silently never executed by `flutter test`.

---

## Determinism & known gaps

- **Time:** use `fakeAsync` for time-based logic (timers, debounce, timeouts).
  `event_transformers_test.dart` is the reference — it drives the bloc inside
  `fakeAsync` and advances virtual time with `async.elapse(...)`, with no
  wall-clock dependency. `idle_timeout_observer_test.dart` uses the same approach.
- **Mocked async:** do not use real-time `blocTest(wait:)` to "let a mock settle"
  — `blocTest` already awaits the bloc's state stream. Sequence dependent events
  with `await bloc.stream.firstWhere((s) => s is <State>)`, not a millisecond delay.
- **Fixtures:** use the fixed `kTestInstant` (`test/mocks/fake_data.dart`) for any
  fixture timestamp whose exact value no assertion depends on — never `DateTime.now()`.
- **Goldens:** golden / visual-regression tests use `alchemist` (`test/goldens/`).
  The bootstrap sets a default `AlchemistConfig` (light theme) and **disables
  platform goldens**, so only the CI (Ahem-rendered) variant runs — identical on
  macOS/Linux/CI, no font flake. Golden files set `setUpAll(() => TestEnv.autoReset
  = false)` and use `pumpBeforeTest: pumpOnce` for animated widgets. Regenerate with
  `flutter test --tags golden --update-goldens`. Coverage: all design-system
  components (`test/goldens/components/`), shared widgets (`test/goldens/widgets/`),
  and key screens (`test/goldens/screens/`, rendered with mocked BLoCs via the
  `goldenScreen` helper) — 60 goldens, light + dark. The responsive **shell /
  home screen is intentionally not goldened** (it boots via real DI in
  `App().buildHomeApp()` rather than mockable to a single deterministic frame; its
  sub-widgets are already covered by the component/widget goldens).
- **Tags:** `dart_test.yaml` declares `widget` (applied to all `testWidgets`
  files via `@Tags(['widget'])`), plus `golden` and `integration` reserved for
  #135/#152. Slice the suite with `flutter test --tags widget` /
  `--exclude-tags widget`. The per-test timeout (30s) lives in `dart_test.yaml`.
- **Pumping:** use `pumpAndSettle()` only when all animations are expected to
  **finish** (route/page transitions, one-shot reveals). Its `Duration` argument
  is the **per-pump interval, not a timeout** (the timeout is a separate, later
  parameter) — prefer the bare form. For **continuous / indeterminate
  animations** (spinner, shimmer, looping) never `pumpAndSettle` (it pumps until
  the 10-minute timeout) — assert the spinner with `pump()` and use
  `pump(const Duration(...))` for a fixed frame; in goldens use
  `pumpBeforeTest: pumpOnce`.

These are documented so newcomers know what is intentional vs. not-yet-done.

---

## Coverage

CI computes line coverage with generated/bootstrap code excluded, via
`scripts/check_coverage.sh` (excludes `lib/generated/**`, `*.g.dart`,
`*.freezed.dart`, `lib/main/main_*.dart`, `*.config.dart`). The current floor is
65%. Run locally:

```shell
fvm flutter test --coverage
scripts/check_coverage.sh coverage/lcov.info 65
```

---

## Running tests

```shell
fvm flutter test                                   # whole suite
fvm flutter test test/features/users               # a subtree
fvm flutter test test/path/to/specific_test.dart   # one file
fvm flutter test --coverage                         # with coverage
fvm flutter test --concurrency=1 --test-randomize-ordering-seed=random  # flush order/leak bugs
```

---

## Adding tests for a new feature

1. Create `test/features/<feature>/` mirroring the feature's `lib/` structure.
2. **Use case tests** (`application/usecases/`): mock the repository interface
   (`MockI<Feature>Repository`) with `mocktail`.
3. **BLoC/Cubit tests** (`application/`): `blocTest`, assert sealed state
   variants; mock the use case or repository.
4. **Repository tests** (`data/repositories/`): `TestEnv.apiClient()` or a stub
   Dio.
5. **Widget tests** (`presentation/`): `MockBloc` for state; `TestEnv.authenticate()`
   in `setUp`/body for auth-gated screens.
6. Add any new mocks/fakes to `test/mocks/mock_classes.dart` (and register
   fallbacks in `registerAllFallbackValues()` if you use `any()` with a new
   non-nullable type).
7. Do **not** add per-file binding/logger/storage setup — the bootstrap handles
   it. Only opt out (`TestEnv.autoReset = false`) if your file installs its own
   channel/prefs mock.

---

## File reference

| Purpose | Path |
| --- | --- |
| Global bootstrap | `test/flutter_test_config.dart` |
| Test-support harness | `test/support/test_env.dart` |
| Shared mocks/fakes | `test/mocks/mock_classes.dart`, `test/mocks/fake_data.dart` |
| Layer dependency guard | `test/architecture/import_guard_test.dart` |
| Test-file naming guard | `test/architecture/test_file_naming_test.dart` |
| Coverage gate | `scripts/check_coverage.sh` |
| Mock data layer | [`docs/mock-architecture.md`](mock-architecture.md) |
| Conventions | `CLAUDE.md` → Testing |
