import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/app/router/app_router_strategy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Utility class for the tests
///
/// This class contains utility methods that are used in the tests
class TestUtils {
  /// Initialize the dependencies for the BLoC tests
  ///
  /// This method initializes the following dependencies: <p>
  /// 1. Flutter Test Binding <p>
  /// 3. Shared Preferences <p>
  /// 4. Equatable Configuration <p>
  /// 5. Mock Method Call Handler for Path Provider <p>

  Future<void> setupUnitTest() async {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
    ProfileConstants.setEnvironment(Environment.test);
    TestWidgetsFlutterBinding.ensureInitialized();
    EquatableConfig.stringify = true;
    await _clearStorage();
    await AppLocalStorage().save(StorageKeys.language.name, "en");
    AppRouter().setRouter(RouterType.goRouter);
  }

  Future<void> setupRepositoryUnitTest() async {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
    ProfileConstants.setEnvironment(Environment.test);
    await _clearStorage();
    await AppLocalStorage().save(StorageKeys.language.name, "en");
    AppRouter().setRouter(RouterType.goRouter);
  }

  Future<void> tearDownUnitTest() async {
    ApiClient.reset();
    return await _clearStorage();
  }

  // add mock token to storage
  Future<void> setupAuthentication() async {
    await AppLocalStorage().save(StorageKeys.jwtToken.name, "MOCK_TOKEN");
  }

  Future<void> _clearStorage() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await AppLocalStorage().clear();
  }
}
