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

No `mockito`, no `build_runner` for mocks — `mocktail` is the single mocking
library. The end-to-end smoke is a full-app widget test under `test/integration/`
(see below) — it runs headless under `flutter test`, so the `integration_test`
package is not a dependency.

---

## Directory layout

`test/` mirrors `lib/`:

```
test/
├── flutter_test_config.dart   # GLOBAL bootstrap (auto-discovered by flutter test)
├── support/
│   ├── dart_code.dart         # codeOnly(): Dart source without comments and string text, for guards
│   └── test_env.dart          # TestEnv: reset(), authenticate(), apiClient(), autoReset
├── mocks/
│   ├── mock_classes.dart      # Mock*/Fake* classes + registerAllFallbackValues()
│   └── fake_data.dart         # Shared fixtures (mockUserFullPayload, ...)
├── architecture/              # Meta-tests enforcing rules (see below)
│   ├── android_manifest_test.dart    # Android INTERNET, backup off
│   ├── credential_to_string_test.dart # a class with a credential field keeps it out of toString
│   ├── demo_values_not_hard_coded_test.dart # no demo URL, path or contact in web/ or lib/
│   ├── feature_generator_test.dart   # tool/generate_feature.dart output is clean and passes its tests
│   ├── import_guard_test.dart        # layer dependency rules, url_launcher only in external_link.dart
│   ├── log_placeholders_test.dart    # every AppLogger call has one {} for each argument
│   ├── log_secrets_test.dart         # no AppLogger call passes a value named for a credential
│   ├── macos_entitlements_test.dart  # macOS sandbox keeps network.client
│   ├── mock_asset_coverage_test.dart # every repository method succeeds on the mock
│   ├── mock_asset_naming_test.dart   # mock asset names use '_', never '-'
│   ├── test_file_naming_test.dart    # forbids *.test.dart (dot) files
│   ├── web_history_test.dart         # web/index.html leaves the browser history to Flutter
│   ├── web_placeholders_test.dart    # demo values cover every web/ and build-time placeholder
│   └── web_sitemap_test.dart         # sitemap lists only the canonical root page
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
  AutomatedTestWidgetsFlutterBinding.instance.defaultTestTimeout = const Timeout.factor(1); // see "Timeouts" below
  AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  EquatableConfig.stringify = true;
  registerAllFallbackValues();

  // Per-test in every file, opted out or not (see "The asset cache" below).
  setUp(rootBundle.clear);
  tearDown(rootBundle.clear);

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
| `TestEnv.reset()` | Re-installs the secure-storage mock and clears all storage. No language is stored, so an `App` starts in the language passed to it, as on a first launch. Called automatically by the bootstrap. |
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

A mock on a channel the reset never touches needs no opt-out.
`test/support/url_launcher_stub.dart` installs one for url_launcher in the test body and removes it when the test ends, so its tests keep the reset and `TestEnv.authenticate()`.

### The asset cache

`rootBundle` caches the `Future` of every string asset it loads, including the `assets/mock/*.json` files behind `MockInterceptor` and `MenuRepository`.
Code that awaits a cached `Future` is resumed by a microtask of the zone that created it.
Each `testWidgets` body runs in its own `FakeAsync` zone, and nothing runs that zone's microtasks once the test ends.
So once a `testWidgets` had loaded an asset, every later `testWidgets` in the same file that needed it waited forever: only the first test of a file got its mock responses, and the others hung until they timed out.
The bootstrap therefore empties the cache with `rootBundle.clear()` before and after every test, in every file, including files that opt out of `TestEnv.reset()`, so no test's cached `Future` outlives it, not even into a later group's `setUpAll`.
`test/support/test_env_test.dart` and `test/flutter_test_config_test.dart` guard this.

### Timeouts

Every test, `testWidgets` included, times out after the 30 seconds set in `dart_test.yaml`, or twice that in a file tagged `@Tags(['integration'])`.
On its own, `testWidgets` passes the binding's `defaultTestTimeout` of 10 minutes to `test()`, and a test's own duration replaces the configured timeout, so a hung widget test held CI for 10 minutes.
The bootstrap sets `defaultTestTimeout` to `Timeout.factor(1)`, which keeps the configured timeout as a plain `test()` does, and `test/flutter_test_config_test.dart` guards it.
A test that needs longer gets its own timeout and a comment that says why, as `test/architecture/feature_generator_test.dart` has `@Timeout(Duration(minutes: 5))` for its nested `flutter test` run, instead of a higher timeout for everyone in `dart_test.yaml`.

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
  await tester.pumpWidget(const App(language: 'en'));
  await tester.pumpAndSettle();
  expect(find.byType(ResponsiveScaffold), findsOneWidget);
});
```

Provide BLoC state with a `MockBloc` so the UI renders deterministically without
real business logic.

**Verifying actions — by event type, not `any()`.** Assert the dispatched event
with a type matcher and an explicit count:

```dart
verify(() => bloc.add(any(that: isA<UserEditorSubmit>()))).called(1);   // action fired
verifyNever(() => bloc.add(any(that: isA<UserEditorSubmit>())));        // must NOT fire (e.g. invalid form)
```

Do **not** use `verify(() => bloc.add(any())).called(...)` or `.called(greaterThan(0))`:
screens add an init event on mount (a load/`Reset`), so a loose verify is satisfied
even if the action under test never fired — a false-confidence test. (A real case:
a "submit valid form" test passed under `add(any())` while the form was actually
invalid — a required field unfilled — so no submit ever dispatched. Tightening to
`isA<…Submit>()` exposed it; the fix was to make the test fill a genuinely valid form.)

**Other screen-test rules:** don't keep a repository mock that isn't injected (the
screen is driven through its mock BLoC); prefer `whenListen` + a seeded state over
re-implementing the bloc's state machine inside an `add` stub; use unique fixture
values so `findsOneWidget` is unambiguous (avoid common tokens like `'User'`); size
the test surface with `tester.view.physicalSize` + `addTearDown(tester.view.reset)`
(one consistent API — not `binding.setSurfaceSize`); and assert navigation by what
the destination renders, not just that the source screen disappeared.

### Widget tests that send a request

A `testWidgets` body runs in fake time, and `tester.pump()` without a duration does not move it: it runs microtasks and draws a scheduled frame, but it fires no timer, not even one of zero length.
Dio runs each interceptor step in a `Future`, which starts on a zero-length `Timer`, so a request through `ApiClient`, whether the test sends it through `TestEnv.apiClient()` or the pumped app sends it, stays where it is however often the test calls `pump()`.
A test that ends there fails with `A Timer is still pending even after the widget tree was disposed` and a stack through `DioMixin.fetch`.
Awaiting the request in the test body is worse: nothing pumps while the body waits, so the test hangs until it times out.

Start the request without awaiting it, pump with a duration, then check or await the result:

```dart
TestEnv.authenticate(); // the secure store is empty at the start of every test, and /account needs a token
Response<String>? response;
unawaited(TestEnv.apiClient().get('/account').then((value) => response = value));
await tester.pump(Duration.zero); // any duration fires the timers that are due, Duration.zero included

expect(response, isNotNull, reason: 'the mock request never completed');
```

`pumpAndSettle()` completes such a request as well, because its first pump advances 100 ms, but it stops as soon as no frame is scheduled.
So it does not wait out the 500 ms that `MockInterceptor` adds under `AppConfig.dev()`, which `App` uses unless the test passes other dependencies: pump at least that long before settling, as `pumpAppOnSettings` in `test/features/settings/presentation/pages/settings_screen_test.dart` does.
Every test that pumps `App` sends at least one request: the lifecycle check reads `GET /app/config` when the app starts.
Do not use `tester.runAsync` to let a mock request finish: it runs the request in real time, and it is meant for real I/O.
`test/support/test_env_test.dart` shows the pattern.

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

### End-to-end smoke

`test/integration/app_smoke_test.dart` boots the **whole app** in mock mode
(`App`'s default `AppDependencies` = `AppConfig.dev()`, which serves
`assets/mock/*.json`) and drives cold-start → login → dashboard, exercising
routing + DI + BLoCs + the mock HTTP layer together. It is a full-app widget test
(`TestWidgetsFlutterBinding`), so it runs headless under the normal
`flutter test` — no device, no `integration_test` package, no CI changes. The
global bootstrap supplies the secure-storage mock + a clean storage reset, so the
app starts unauthenticated and lands on login. Scope is one happy-path smoke — not
multi-flow e2e. (For real on-device e2e later, add `integration_test` back and a
device-targeted CI job.)

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
  It also fails if a file other than `lib/shared/utils/external_link.dart` imports `url_launcher`.
  Links go through `openExternalLink`, which tells the user when a link does not open and never asks `canLaunchUrl`, so the Android manifest needs no `<queries>` intent for them.
- **`test_file_naming_test.dart`** fails if any file is named `*.test.dart`
  (a dot instead of `_test.dart`) — such files compile and pass `analyze` but
  are silently never executed by `flutter test`.
- **`macos_entitlements_test.dart`** fails if either macOS entitlement file drops `com.apple.security.network.client`.
  The sandboxed macOS app cannot make outgoing requests without it, the `flutter create` template omits it, and no CI job builds macOS.
- **`android_manifest_test.dart`** fails if `AndroidManifest.xml` drops the `INTERNET` permission, `android:allowBackup="false"`, or the references to the two backup rule files, or if either rule file stops excluding shared preferences.
  Release builds need the permission to reach the API, and a restored backup or device transfer brings back session tokens that no longer decrypt.
  CI builds the release APK, but that build succeeds without any of these.
- **`mock_asset_naming_test.dart`** fails if a file under `assets/mock/` has a `-` in its name.
  `MockInterceptor` maps `-` in request paths to `_`, so such a file is never served and the request fails with 501.
- **`mock_asset_coverage_test.dart`** drives every method of every repository that uses `ApiClient`, and submits each dynamic form the app opens, through `TestEnv.apiClient()`; it fails when one of them does not succeed.
  `MockInterceptor` fails a GET, POST, PUT or PATCH whose mock file is missing with 501, so a missing file fails the test and the failure names it.
  A last test reads the repository interfaces under `lib/` and fails when a method is not driven, so a new repository method needs an entry in the test, and its mock file, before the build passes.
- **`web_placeholders_test.dart`** fails if a `__KEY__` placeholder in `web/index.html`, `manifest.json`, `sitemap.xml`, `humans.txt`, `404.html`, `robots.txt` or `.well-known/security.txt` has no value in `.github/pages/demo-values.env`, apart from `__KEYWORD__` and `__PROD_API_URL__`, which the hosted demo leaves on purpose.
  The GitHub Pages job fills these files in `build/web` from that file and then fails on any placeholder left (`scripts/check_web_placeholders.sh`).
  It also fails if a key that `lib/infrastructure/config/template_config.dart` reads with `String.fromEnvironment` and a placeholder default has no value there: the job builds the app with `--dart-define-from-file` pointing at that file, and a key without a value leaves its placeholder in `main.dart.js`.
  It runs only after a push to `main`, so without this test a missing value would surface as a failed deploy instead of in the pull request.
- **`demo_values_not_hard_coded_test.dart`** fails if a deployment-specific value of `.github/pages/demo-values.env` (any key but `APP_NAME`, `APP_SHORT_NAME` and `APP_DESCRIPTION`) appears verbatim in a file under `web/` or `lib/` (apart from `lib/generated/`), or in `SECURITY.md`.
  Only this repository's Pages job puts those values into a build, so a value written into these files instead would ship the demo's URL, path, author or security contact in every project made from the template.
- **`web_sitemap_test.dart`** fails if `web/sitemap.xml` lists any URL other than the canonical root of `web/index.html`.
  The app keeps Flutter's default hash URL strategy, so a path such as `/login` is not a page of the deployed site and GitHub Pages answers it with 404.
- **`web_history_test.dart`** fails if `web/index.html` listens for `popstate` or `beforeunload`, or replaces `history.back`, `forward`, `go`, `pushState` or `replaceState`.
  Such a script keeps the browser back and forward buttons from reaching go_router, and no widget test can see it, because `flutter test` never loads `web/index.html`.
- **`feature_generator_test.dart`** runs `tool/generate_feature.dart` in a temporary copy of the project and fails if the generated feature is not formatted, does not analyze cleanly or fails its own tests.
  Nothing else compiles the generator's templates, so they drift silently when an API they call changes.
  The generated repository and route tests go through the real `ApiClient` and `MockInterceptor`, so a mock file named differently from the request it should answer fails the guard too.
  It is the slowest guard, mostly because of the nested `flutter test` run.
- **`log_placeholders_test.dart`** fails if the message of an `AppLogger` call in `lib/` has a different number of `{}` than the call has arguments.
  `AppLogger` never prints an argument with no `{}` left and prints a `{}` with no argument as it is, so such a call leaves a value out of the line or shows a bare `{}`, and neither fails at runtime or in `flutter analyze`.
  It reads the calls whose message is a string literal and whose arguments are a list literal.
- **`log_secrets_test.dart`** fails if an argument of an `AppLogger` call in `lib/`, or an interpolation in its message, names a credential: an identifier that contains one of `sensitiveBodyKeySubstrings`, such as `passwordChangeDTO` or `event.otpCode`.
  The console of every build that prints the level keeps the line, so log that the action happened instead.
  A token may still be logged through `maskToken`, which keeps four characters at each end.
- **`credential_to_string_test.dart`** fails if a class in `lib/` has a `String` field whose name contains one of `sensitiveBodyKeySubstrings`, such as `password`, `otpCode` or `refreshToken`, and its `toString` is not overridden, prints such a field, or prints the props.
  A log line, the dev console and a Sentry event print an object through `toString`, and an Equatable prints its props there whenever `stringify` is on, the default of every debug build.
  A token may be printed through `maskToken`; a password or an OTP is printed as `secretMask`.

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
- **Goldens:** golden / visual-regression tests use `alchemist`. Each golden test
  lives **next to the code it covers** (feature-first, mirroring `lib/` — same as
  every other test), with its images in a sibling `goldens/ci/` dir; e.g.
  `test/shared/design_system/components/app_button_golden_test.dart`,
  `test/features/users/presentation/pages/user_list_page_golden_test.dart`. The
  bootstrap sets a default `AlchemistConfig` (light theme) and **disables platform
  goldens**, so only the CI (Ahem-rendered) variant runs — identical on
  macOS/Linux/CI, no font flake. Golden files set `setUpAll(() => TestEnv.autoReset
  = false)` and use `pumpBeforeTest: pumpOnce` for animated widgets. Regenerate with
  `flutter test --tags golden --update-goldens`. Coverage: all design-system
  components, shared widgets, and key screens (rendered with mocked BLoCs via the
  `test/support/golden_app.dart` `goldenScreen` helper) — 60 goldens, light + dark.
  The responsive **shell / home screen is intentionally not goldened** (it boots
  via real DI in
  `App()` rather than mockable to a single deterministic frame; its
  sub-widgets are already covered by the component/widget goldens).
- **Tags:** `dart_test.yaml` declares `widget` (applied to all `testWidgets`
  files via `@Tags(['widget'])`) and `golden` (auto-applied by alchemist). An
  `integration` tag is declared but reserved for a possible future on-device
  (`flutter drive`) suite — the current e2e smoke is a `test/integration/` widget
  test (tagged `widget`). Slice the suite with `flutter test --tags widget` /
  `--exclude-tags widget`.
  The per-test timeout (30s) lives in `dart_test.yaml` and applies to `testWidgets` too (see "Timeouts" above).
- **Pumping:** use `pumpAndSettle()` only when all animations are expected to **finish** (route/page transitions, one-shot reveals).
  Its `Duration` argument is the **per-pump interval, not a timeout** (the timeout is a separate, later parameter), so prefer the bare form.
  For **continuous / indeterminate animations** (spinner, shimmer, looping) never `pumpAndSettle`: it pumps until its own timeout of 10 minutes of fake time, 6000 frames at the default interval, and then throws `pumpAndSettle timed out`, usually within seconds, unless slow frames reach the 30 second test timeout first.
  Assert the spinner with `pump()` and use `pump(const Duration(...))` for a fixed frame; in goldens use `pumpBeforeTest: pumpOnce`.

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
   Add each repository method that sends requests through `ApiClient` to the table in `test/architecture/mock_asset_coverage_test.dart`.
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
| macOS network entitlement guard | `test/architecture/macos_entitlements_test.dart` |
| Android manifest guard | `test/architecture/android_manifest_test.dart` |
| Mock asset naming guard | `test/architecture/mock_asset_naming_test.dart` |
| Mock asset coverage guard | `test/architecture/mock_asset_coverage_test.dart` |
| Web demo values guard | `test/architecture/web_placeholders_test.dart` |
| Demo values not hard-coded guard | `test/architecture/demo_values_not_hard_coded_test.dart` |
| Web sitemap guard | `test/architecture/web_sitemap_test.dart` |
| Web history guard | `test/architecture/web_history_test.dart` |
| Feature generator guard | `test/architecture/feature_generator_test.dart` |
| Log placeholder guard | `test/architecture/log_placeholders_test.dart` |
| Log secrets guard | `test/architecture/log_secrets_test.dart` |
| Credential text guard | `test/architecture/credential_to_string_test.dart` |
| Coverage gate | `scripts/check_coverage.sh` |
| Mock data layer | [`docs/mock-architecture.md`](mock-architecture.md) |
| Conventions | `CLAUDE.md` → Testing |
