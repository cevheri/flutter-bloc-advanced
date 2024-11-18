import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for the tests
///
/// This class contains utility methods that are used in the tests
class TestUtils {
  /// Initialize the dependencies for the BLoC tests
  ///
  /// This method initializes the following dependencies: <p>
  /// 1. JsonMapper <p>
  /// 2. Flutter Test Binding <p>
  /// 3. Shared Preferences <p>
  /// 4. Equatable Configuration <p>
  /// 5. Mock Method Call Handler for Path Provider <p>


  Future<void> setupUnitTest() async {
    ProfileConstants.setEnvironment(Environment.TEST);
    initializeJsonMapper();
    TestWidgetsFlutterBinding.ensureInitialized();
    EquatableConfig.stringify = true;
    await clearStorage();
    await AppLocalStorage().save(StorageKeys.language.name, "en");
    await AppLocalStorageCached.loadCache();
  }

  Future<void> clearStorage() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalStorage().clear();
  }

  // add mock token to storage
  Future<void> addMockTokenToStorage() async {
    await AppLocalStorage().save(StorageKeys.jwtToken.name, "UNITTEST_TOKEN");
  }

  Future<void> tearDownUnitTest() async {
    return await clearStorage();
  }
}
