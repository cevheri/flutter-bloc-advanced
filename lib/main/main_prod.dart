import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
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

  AppLogger.configure(isProduction: true);
  final log = AppLogger.getLogger("main_prod.dart");
  log.info("Starting App with env: {}", [Environment.prod.name]);

  initializeJsonMapper();
  WidgetsFlutterBinding.ensureInitialized();

  const defaultLanguage = "en";
  await AppLocalStorage().save(StorageKeys.language.name, defaultLanguage);

  WidgetsFlutterBinding.ensureInitialized();
  const initialTheme = AdaptiveThemeMode.dark;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(App(language: defaultLanguage, initialTheme: initialTheme));
  });
  log.info("Started App with env: {} language: {} and theme: {}", [Environment.prod.name, defaultLanguage, initialTheme.name]);
}
