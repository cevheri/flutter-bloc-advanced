import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap_config.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/analytics/crash_reporter.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_bloc_observer.dart';
import 'package:flutter_bloc_advance/core/analytics/log_analytics_service.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/app/router/app_router_strategy.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';

class AppBootstrap {
  static Future<void> run(AppBootstrapConfig config) async {
    WidgetsFlutterBinding.ensureInitialized();

    await AppConstants.initPackageInfo();

    AppLogger.configure(isProduction: config.isProduction);
    final log = AppLogger.getLogger('AppBootstrap');

    ProfileConstants.setEnvironment(config.environment);

    final existingLang = await AppLocalStorage().read(StorageKeys.language.name);
    if (existingLang == null) {
      await AppLocalStorage().save(StorageKeys.language.name, config.defaultLanguage);
    }
    final existingPalette = await AppLocalStorage().read(StorageKeys.theme.name);
    if (existingPalette == null) {
      await AppLocalStorage().save(StorageKeys.theme.name, config.defaultPalette);
    }
    // Don't save default brightness — let ThemeBloc use ThemeMode.system when no preference exists
    await AppLocalStorageCached.loadCache();

    // Connectivity monitoring
    await ConnectivityService.instance.initialize();

    // Analytics & crash reporting
    final analytics = LogAnalyticsService();
    CrashReporter.install(analytics);

    if (kDebugMode) {
      Bloc.observer = TimeTravelBlocObserver();
    }

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
        analytics: analytics,
      ),
    );
  }
}
