import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/analytics/analytics_route_observer.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_session_listeners.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/di/app_scope.dart';
import 'package:flutter_bloc_advance/app/localization/locale_cubit.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/app/router/app_router.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';
import 'package:flutter_bloc_advance/core/analytics/log_analytics_service.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/lifecycle_gate.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    required this.language,
    this.dependencies = const AppDependencies(),
    this.secureStorage,
    this._analytics,
  });

  /// The configured default language: the app shows it until a language is stored on the device, see [LocaleCubit].
  final String language;
  final AppDependencies dependencies;

  /// Single [ISecureStorage] instance created in bootstrap. Threaded
  /// through so the same adapter handles bootstrap-time migration AND
  /// runtime consumers (repositories, interceptors, SessionCubit) —
  /// avoids divergent instances if adapter configuration ever varies
  /// and makes overriding for tests / alternate environments trivial.
  /// When null, [AppScope] falls back to [AppDependencies.createSecureStorage].
  final ISecureStorage? secureStorage;
  final IAnalyticsService? _analytics;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  /// The ScaffoldMessenger of MaterialApp.router. [AppSessionListeners] sits above MaterialApp, where its context finds
  /// no ScaffoldMessenger, so it shows its notices through this key.
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// The activity that the browser tabs share for the idle timeout, on web; see
  /// [AppDependencies.createSharedActivityStore].
  late final _sharedActivity = widget.dependencies.createSharedActivityStore();

  @override
  Widget build(BuildContext context) {
    final analytics = widget._analytics ?? LogAnalyticsService();
    return AppScope(
      dependencies: widget.dependencies,
      secureStorage: widget.secureStorage,
      defaultLocale: Locale(widget.language),
      child: AppSessionListeners(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        sharedActivity: _sharedActivity,
        child: _AppView(analytics: analytics, scaffoldMessengerKey: _scaffoldMessengerKey),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView({required this.analytics, required this.scaffoldMessengerKey});

  final IAnalyticsService analytics;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  GoRouter? _router;
  UnsavedChangesRegistry? _unsavedChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_router != null) return;
    final routerFactory = AppRouterFactory(
      sessionCubit: context.read<SessionCubit>(),
      authMode: context.read<AuthMode>(),
      observers: [
        AnalyticsRouteObserver(widget.analytics),
        // Sentry breadcrumbs from navigation. Only meaningful when the
        // Sentry SDK was initialized in bootstrap (production + DSN);
        // outside that window the observer is harmless overhead.
        if (context.read<AppConfig>().sentryDsn != null) SentryNavigatorObserver(),
      ],
    );
    final router = _router = routerFactory.create();
    _unsavedChanges = UnsavedChangesRegistry(isExitForced: routerFactory.isExitForced);
    // The Router is mounted only once the session is restored (see build), and go_router's route information provider
    // receives the routes the platform pushes, such as an iOS universal link that opens the app, only while something
    // listens to it. This listener keeps it receiving them from the start, so the Router opens a route pushed during
    // the restore when it mounts.
    router.routeInformationProvider.addListener(_receivePlatformRoutes);
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_receivePlatformRoutes);
    super.dispose();
  }

  /// Does nothing itself: while it listens, the route information provider is registered with [WidgetsBinding] and
  /// keeps the routes the platform pushes.
  static void _receivePlatformRoutes() {}

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      // A new language, or the end of restore, which lets the router in.
      buildWhen: (previous, current) => previous.locale != current.locale || previous is LocaleRestoring,
      builder: (context, localeState) => BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            scaffoldMessengerKey: widget.scaffoldMessengerKey,
            // The name the task switcher and the browser tab show, in the app language.
            onGenerateTitle: (context) => S.of(context).app_title,
            theme: AppTheme.light(themeState.palette),
            darkTheme: AppTheme.dark(themeState.palette),
            themeMode: themeState.themeMode,
            themeAnimationDuration: Duration.zero,
            debugShowCheckedModeBanner: true,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: localeState.locale,
            routerConfig: _router!,
            // The router's first redirect must see the restored session: while the session is unknown it treats a
            // signed-in user as signed out, shows the login page and loses a deep link. So the router is mounted, and
            // its first route parsed, only once restore has settled the session. Later sign-ins and sign-outs are left
            // to its redirect. It also waits for the stored language, so the first page shows in it.
            // The registry sits above the router, so the routes' onExit and the pages' UnsavedChangesScope find it.
            // LifecycleGate shows the maintenance or update screen in place of all of it when the app config asks for
            // one, and mounts the router again once the app may open.
            builder: (context, router) => RepositoryProvider<UnsavedChangesRegistry>.value(
              value: _unsavedChanges!,
              child: LifecycleGate(
                child: BlocBuilder<SessionCubit, SessionState>(
                  buildWhen: (previous, current) => previous is SessionUnknown,
                  builder: (context, session) => switch (session) {
                    SessionUnknown() => const _RestoreView(),
                    SessionAuthenticated() || SessionUnauthenticated() => switch (localeState) {
                      LocaleRestoring() => const _RestoreView(),
                      LocaleReady() || LocaleChanging() || LocaleChangeFailure() => router!,
                    },
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shown while [SessionCubit.restore] reads the stored session and [LocaleCubit.restore] the stored language.
/// Continues the web startup screen (`#loading` in web/index.html): a 56 px ring spinner with a 4 px stroke, centered
/// on the theme background.
class _RestoreView extends StatelessWidget {
  const _RestoreView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface,
      child: Center(
        child: SizedBox.square(
          dimension: 56,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            strokeAlign: CircularProgressIndicator.strokeAlignInside,
            color: colorScheme.onSurfaceVariant,
            backgroundColor: colorScheme.outline,
            semanticsLabel: S.of(context).loading,
          ),
        ),
      ),
    );
  }
}
