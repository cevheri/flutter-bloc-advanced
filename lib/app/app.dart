import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/analytics/analytics_route_observer.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_session_listeners.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/di/app_scope.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/app/router/app_router.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';
import 'package:flutter_bloc_advance/core/analytics/log_analytics_service.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/web_back_button_disabler.dart';
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

  @override
  Widget build(BuildContext context) {
    final analytics = widget._analytics ?? LogAnalyticsService();
    return AppScope(
      dependencies: widget.dependencies,
      secureStorage: widget.secureStorage,
      child: AppSessionListeners(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        child: _AppView(language: widget.language, analytics: analytics, scaffoldMessengerKey: _scaffoldMessengerKey),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView({required this.language, required this.analytics, required this.scaffoldMessengerKey});

  final String language;
  final IAnalyticsService analytics;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_router != null) return;
    final router = _router = AppRouterFactory(
      sessionCubit: context.read<SessionCubit>(),
      observers: [
        AnalyticsRouteObserver(widget.analytics),
        // Sentry breadcrumbs from navigation. Only meaningful when the
        // Sentry SDK was initialized in bootstrap (production + DSN);
        // outside that window the observer is harmless overhead.
        if (context.read<AppConfig>().sentryDsn != null) SentryNavigatorObserver(),
      ],
    ).create();
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
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return WebBackButtonDisabler(
          child: MaterialApp.router(
            scaffoldMessengerKey: widget.scaffoldMessengerKey,
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
            locale: Locale(widget.language),
            routerConfig: _router!,
            // The router's first redirect must see the restored session: while the session is unknown it treats a
            // signed-in user as signed out, shows the login page and loses a deep link. So the router is mounted, and
            // its first route parsed, only once restore has settled the session. Later sign-ins and sign-outs are left
            // to its redirect.
            builder: (context, router) => BlocBuilder<SessionCubit, SessionState>(
              buildWhen: (previous, current) => previous is SessionUnknown,
              builder: (context, session) => switch (session) {
                SessionUnknown() => const _SessionRestoreView(),
                SessionAuthenticated() || SessionUnauthenticated() => router!,
              },
            ),
          ),
        );
      },
    );
  }
}

/// Shown while [SessionCubit.restore] reads the stored session. Continues the web startup screen (`#loading` in
/// web/index.html): a 56 px ring spinner with a 4 px stroke, centered on the theme background.
class _SessionRestoreView extends StatelessWidget {
  const _SessionRestoreView();

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
