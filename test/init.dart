import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_bloc_advance/utils/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initialize the dependencies for the BLoC tests
///
/// This method initializes the following dependencies: <p>
/// 1. JsonMapper <p>
/// 2. Flutter Test Binding <p>
/// 3. Shared Preferences <p>
/// 4. Equatable Configuration <p>
/// 5. Mock Method Call Handler for Path Provider <p>
void initBlocDependencies() {
  ProfileConstants.setEnvironment(Environment.TEST);
  initializeJsonMapper();
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  EquatableConfig.stringify = true;

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall methodCall) async {
    return '.';
  });

  GetStorage.init();

  final storageData = getStorageCache;
  final language = storageData["language"];
  if (language == null) {
    saveStorage(language: 'en');
  }

}
