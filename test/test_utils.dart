import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/app/router/app_router_strategy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Utility class for the tests
///
/// This class contains utility methods that are used in the tests
class TestUtils {
  /// In-memory backing for the mocked flutter_secure_storage channel.
  ///
  /// Production code instantiates [FlutterSecureStorageAdapter] in
  /// several places — `AuthInterceptor`, `TokenRefreshInterceptor`,
  /// `SessionCubit`, `AuthSessionRepository`, `LoginRepository.logout`,
  /// `SessionMigration` — and each adapter call routes through this
  /// MethodChannel. Without a mock, every test that touches those paths
  /// would throw `MissingPluginException`.
  static final Map<String, String> _secureStore = {};

  static const _secureChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  /// Always re-installs the handler. Previously short-circuited via
  /// a `_secureMockInstalled` flag, but `secure_storage_test.dart`
  /// (C3 throw-on-failure contract tests) temporarily overrides the
  /// same channel and its `tearDown` resets the handler to `null`.
  /// If this util ran first and set the flag, a later run of
  /// `setupUnitTest()` would skip re-installation and leave the
  /// channel with the null handler → `MissingPluginException` for
  /// every secure-storage call. Re-installing is cheap and
  /// idempotent.
  static void _installSecureStorageMock() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_secureChannel, (
      call,
    ) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? const {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return _secureStore[key];
        case 'readAll':
          return Map<String, String>.from(_secureStore);
        case 'write':
          _secureStore[key!] = args['value'] as String;
          return null;
        case 'delete':
          _secureStore.remove(key);
          return null;
        case 'deleteAll':
          _secureStore.clear();
          return null;
        case 'containsKey':
          return _secureStore.containsKey(key);
        default:
          return null;
      }
    });
  }

  Future<void> setupUnitTest() async {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
    ProfileConstants.setEnvironment(Environment.test);
    TestWidgetsFlutterBinding.ensureInitialized();
    EquatableConfig.stringify = true;
    _installSecureStorageMock();
    // Wire ApiClient to a shared FlutterSecureStorageAdapter so the
    // HTTP interceptors read from the same MethodChannel-mocked store
    // as the repository layer. Without this, tests touching both
    // ApiClient.instance and a repository would silently use two
    // different adapter instances — both backed by the same mock so
    // tests pass, but the test harness would not catch a future
    // production refactor that breaks SoT.
    ApiClient.secureStorage = FlutterSecureStorageAdapter();
    await _clearStorage();
    await AppLocalStorage().save(StorageKeys.language.key, "en");
    AppRouter().setRouter(RouterType.goRouter);
  }

  Future<void> setupRepositoryUnitTest() async {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
    ProfileConstants.setEnvironment(Environment.test);
    // Binding must be initialized BEFORE installing the MethodChannel
    // mock — `TestDefaultBinaryMessengerBinding.instance` throws
    // otherwise. setupUnitTest does the same.
    TestWidgetsFlutterBinding.ensureInitialized();
    _installSecureStorageMock();
    ApiClient.secureStorage = FlutterSecureStorageAdapter();
    await _clearStorage();
    await AppLocalStorage().save(StorageKeys.language.key, "en");
    AppRouter().setRouter(RouterType.goRouter);
  }

  Future<void> tearDownUnitTest() async {
    ApiClient.reset();
    // [ApiClient.reset] now also clears `secureStorage` and
    // `onSessionExpired` (Copilot finding: hot-reload / multi-test
    // leakage). Test files that rely on `setUpAll` + per-test
    // `tearDown` (instead of per-test `setUp`) would otherwise see a
    // null `secureStorage` after the first teardown. Re-wire the
    // shared adapter here so the next test in the same file starts
    // with the same SoT invariants `setupUnitTest` established.
    _installSecureStorageMock();
    ApiClient.secureStorage = FlutterSecureStorageAdapter();
    return await _clearStorage();
  }

  /// Seed a mock JWT in the secure-store backing. This is the only
  /// place tokens live in the shipped architecture — `AuthInterceptor`
  /// and `SessionCubit.restore` both read it on demand. `SecurityUtils`
  /// itself takes the token as an argument (no I/O), so seeding here
  /// is sufficient for any auth-dependent test path.
  ///
  /// Synchronous: the backing is just an in-memory map and tests have
  /// historically called this without `await`. Keeping it sync makes
  /// the no-await call sites correct rather than racy.
  void setupAuthentication() {
    _secureStore[SecureStorageKeys.jwtToken.key] = 'MOCK_TOKEN';
  }

  Future<void> _clearStorage() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    _secureStore.clear();
    await AppLocalStorage().clear();
  }
}
