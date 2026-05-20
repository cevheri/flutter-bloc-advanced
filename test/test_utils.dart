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

  static bool _secureMockInstalled = false;

  static void _installSecureStorageMock() {
    if (_secureMockInstalled) return;
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
    _secureMockInstalled = true;
  }

  Future<void> setupUnitTest() async {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
    ProfileConstants.setEnvironment(Environment.test);
    TestWidgetsFlutterBinding.ensureInitialized();
    EquatableConfig.stringify = true;
    _installSecureStorageMock();
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
    await _clearStorage();
    await AppLocalStorage().save(StorageKeys.language.key, "en");
    AppRouter().setRouter(RouterType.goRouter);
  }

  Future<void> tearDownUnitTest() async {
    ApiClient.reset();
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
