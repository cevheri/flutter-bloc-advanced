import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import '../configuration/environment.dart';
import '../utils/storage.dart';
import 'app.dart';
import 'main_local.mapper.g.dart' show initializeJsonMapper;

/// IMPORTANT!! run this command to generate main_prod.mapper.g.dart
// dart run build_runner build --delete-conflicting-outputs
// flutter pub run intl_utils:generate
/// main entry point of local computer development

Map<String, dynamic> getStorageCache = {};

Future<void> loadStorageData() async {
  getStorageCache = await getStorage();
}

void main() async {
  ProfileConstants.setEnvironment(Environment.DEV);
  initializeJsonMapper();
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  final storageData = getStorageCache;
  final language = storageData["language"];
  if (language == null) {
    saveStorage(language: 'en');
  }

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(App(language: language ?? 'en'));
  });
}
