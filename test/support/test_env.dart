import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/app/router/app_router_strategy.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Static test-support harness. Replaces the old instance-based `TestUtils`.
///
/// One-time global config and the per-test reset are wired in
/// `test/flutter_test_config.dart`. Individual test files normally need
/// nothing; files that manage the secure-storage MethodChannel themselves
/// opt out with `setUpAll(() => TestEnv.autoReset = false);`.
class TestEnv {
  TestEnv._();

  /// When false, the global setUp/tearDown in flutter_test_config skip
  /// [reset]. Set in a file's `setUpAll` for tests that install their own
  /// MethodChannel handler (per-file isolate, so it never leaks). Defaults
  /// to true at isolate start.
  static bool autoReset = true;

  /// In-memory backing for the mocked flutter_secure_storage channel.
  /// Production code instantiates [FlutterSecureStorageAdapter] in several
  /// places (AuthInterceptor, TokenRefreshInterceptor, SessionCubit,
  /// AuthSessionRepository, LoginRepository.logout, SessionMigration); each
  /// routes through this MethodChannel. Without the mock those paths throw
  /// MissingPluginException.
  static final Map<String, String> _secureStore = {};

  static const _secureChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  /// Mock-backed client for tests: test AppConfig → MockInterceptor serves
  /// assets/mock/*.json; shared secure adapter → same MethodChannel mock the
  /// repo layer reads. Pass [dio] to inject a stub.
  static ApiClient apiClient({Dio? dio}) =>
      ApiClient(appConfig: const AppConfig.test(), secureStorage: FlutterSecureStorageAdapter(), dio: dio);

  /// Resets the per-test environment: re-installs the secure-storage mock,
  /// clears all storage, seeds language "en", and selects the goRouter
  /// strategy. Idempotent and cheap (in-memory).
  static Future<void> reset() async {
    _installSecureStorageMock();
    await _clearStorage();
    await AppLocalStorage().save(StorageKeys.language.key, 'en');
    AppRouter().setRouter(RouterType.goRouter);
  }

  /// Seeds a mock JWT in the secure-store backing. Call inside a test body or
  /// `setUp` (i.e. AFTER the global reset has cleared the store), never in
  /// `setUpAll`. Synchronous: the backing is just an in-memory map.
  static void authenticate() {
    _secureStore[SecureStorageKeys.jwtToken.key] = 'MOCK_TOKEN';
  }

  /// Always re-installs the handler. `secure_storage_test.dart` temporarily
  /// overrides the same channel and resets the handler to null in its
  /// tearDown; re-installing here is cheap and idempotent.
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

  static Future<void> _clearStorage() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    _secureStore.clear();
    await AppLocalStorage().clear();
  }
}
