import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap_config.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/app/router/app_router_strategy.dart';

class AppBootstrap {
  static Future<void> run(AppBootstrapConfig config) async {
    WidgetsFlutterBinding.ensureInitialized();

    AppLogger.configure(isProduction: config.isProduction);
    final log = AppLogger.getLogger('AppBootstrap');

    ProfileConstants.setEnvironment(config.environment);

    await AppLocalStorage().save(StorageKeys.language.name, config.defaultLanguage);
    await AppLocalStorage().save(StorageKeys.theme.name, config.defaultPalette);
    await AppLocalStorage().save(StorageKeys.brightness.name, config.defaultBrightness);
    await AppLocalStorageCached.loadCache();

    AppRouter().setRouter(RouterType.goRouter);

    await SystemChrome.setPreferredOrientations(config.preferredOrientations);

    log.info('Starting app with env: {}, language: {}, palette: {}, brightness: {}', [
      config.environment.name,
      config.defaultLanguage,
      config.defaultPalette,
      config.defaultBrightness,
    ]);

    runApp(
      App(
        language: config.defaultLanguage,
        dependencies: AppDependencies(environment: config.environment),
      ),
    );
  }
}
