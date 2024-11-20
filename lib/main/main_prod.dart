import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';

import 'app.dart';
import 'main_local.mapper.g.dart' show initializeJsonMapper;

/// IMPORTANT!! run this command to generate main_prod.mapper.g.dart
// dart run build_runner build --delete-conflicting-outputs
// flutter pub run intl_utils:generate

/// main entry point of PRODUCTION
void main() async {
  ProfileConstants.setEnvironment(Environment.prod);
  initializeJsonMapper();
  WidgetsFlutterBinding.ensureInitialized();

  const defaultLanguage = "en";
  await AppLocalStorage().save(StorageKeys.language.name, defaultLanguage);

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const App(language: defaultLanguage));
  });
}
