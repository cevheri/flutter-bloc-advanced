import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';

import 'app.dart';

/// main entry point of local computer development
void main() async {
  // first configure the logger
  AppLogger.configure(isProduction: false);
  final log = AppLogger.getLogger("main_local.dart");

  ProfileConstants.setEnvironment(Environment.dev);

  log.info("Starting App with env: {}", [Environment.dev.name]);

  WidgetsFlutterBinding.ensureInitialized();

  //TODO change to the system language(browser language)
  const defaultLanguage = "en";
  AppLocalStorage().setStorage(StorageType.sharedPreferences);
  await AppLocalStorage().save(StorageKeys.language.name, defaultLanguage);

  AppRouter().setRouter(RouterType.goRouter);

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const App(language: defaultLanguage));
  });

  //TODO change to the system theme(browser theme)
  const defaultThemeName = "system";
  await AppLocalStorage().save(StorageKeys.theme.name, defaultThemeName);

  log.info("Started App with local environment language: {} and theme: {}", [defaultLanguage, defaultThemeName]);
}
