import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap_config.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/analytics/crash_reporter.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_bloc_observer.dart';
import 'package:flutter_bloc_advance/core/logging/app_bloc_observer.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_scrub.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_migration.dart';
import 'package:flutter_bloc_advance/app/router/app_router_strategy.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppBootstrap {
  static Future<void> run(AppBootstrapConfig config) async {
    WidgetsFlutterBinding.ensureInitialized();

    await AppConstants.initPackageInfo();

    AppLogger.configure(isProduction: config.isProduction);
    final log = AppLogger.getLogger('AppBootstrap');

    final appConfig = AppConfig.fromEnvironment(config.environment);
    final dependencies = AppDependencies(appConfig: appConfig);
    ApiClient.appConfig = appConfig;
    final secureStorage = dependencies.createSecureStorage();
    // Publish the same adapter instance into the static [ApiClient]
    // hook so AuthInterceptor and TokenRefreshInterceptor share it
    // with the repository layer and SessionCubit. Invariant: this
    // must run before [ApiClient.instance] is touched anywhere —
    // Dio is built lazily on first access. Any code path that may
    // issue HTTP requests must come below this line.
    ApiClient.secureStorage = secureStorage;

    // One-shot migration of legacy plaintext tokens (jwtToken/refreshToken).
    // Must run BEFORE any consumer reads the secure store (SessionCubit
    // .restore, AuthInterceptor, TokenRefreshInterceptor) so the
    // migrated tokens are available on first use.
    await runSessionMigration(secureStorage: secureStorage, localStorage: AppLocalStorage());

    final existingLang = await AppLocalStorage().read(StorageKeys.language.key);
    if (existingLang == null) {
      await AppLocalStorage().save(StorageKeys.language.key, config.defaultLanguage);
    }
    final existingPalette = await AppLocalStorage().read(StorageKeys.theme.key);
    if (existingPalette == null) {
      await AppLocalStorage().save(StorageKeys.theme.key, config.defaultPalette);
    }
    // Don't save default brightness — let ThemeBloc use ThemeMode.system when no preference exists
    await AppLocalStorageCached.loadCache();

    // Connectivity monitoring
    await ConnectivityService.instance.initialize();

    // Analytics & crash reporting. When `--dart-define=SENTRY_DSN=...`
    // is provided in a production build, [AppDependencies] returns the
    // Sentry-backed implementation. Anywhere else, the local-only
    // logging implementation.
    //
    // CrashReporter always installs framework / PlatformDispatcher hooks for
    // local logging. When Sentry is active it installs its OWN hooks that both
    // capture the error and chain to ours, so we must NOT also forward uncaught
    // errors to the Sentry-backed analytics here — doing so reports every crash
    // twice. With Sentry off, forwarding to the local logging analytics is the
    // only sink, so it stays enabled.
    final analytics = dependencies.createAnalyticsService();
    final sentryActive = appConfig.sentryDsn != null;
    CrashReporter.install(analytics, forwardToAnalytics: !sentryActive);

    Bloc.observer = kDebugMode ? TimeTravelBlocObserver() : AppBlocObserver();

    AppRouter().setRouter(RouterType.goRouter);

    await SystemChrome.setPreferredOrientations(config.preferredOrientations);

    log.info('Starting app with env: {}, language: {}, palette: {}, brightness: {}', [
      config.environment.name,
      config.defaultLanguage,
      config.defaultPalette,
      config.defaultBrightness,
    ]);

    // Reuse the same ISecureStorage that ran the migration above so
    // the entire widget tree shares one adapter instance — no config
    // drift between migration and runtime consumers, and overriding
    // for tests / alternate environments is a single hand-off.
    final dsn = appConfig.sentryDsn;
    if (dsn != null) {
      log.info('Initializing Sentry (release: {}+{})', [AppConstants.appVersion, AppConstants.appBuildNumber]);
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.beforeSend = (event, hint) => sentryBeforeSend(event);
          options.tracesSampleRate = 0.2;
          options.release = '${AppConstants.appVersion}+${AppConstants.appBuildNumber}';
        },
        appRunner: () => runApp(
          App(
            language: config.defaultLanguage,
            dependencies: dependencies,
            secureStorage: secureStorage,
            analytics: analytics,
          ),
        ),
      );
    } else {
      runApp(
        App(
          language: config.defaultLanguage,
          dependencies: dependencies,
          secureStorage: secureStorage,
          analytics: analytics,
        ),
      );
    }
  }
}
