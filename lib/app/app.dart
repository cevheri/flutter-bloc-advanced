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

class App extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final analytics = _analytics ?? LogAnalyticsService();
    return AppScope(
      dependencies: dependencies,
      secureStorage: secureStorage,
      child: AppSessionListeners(
        child: _AppView(language: language, analytics: analytics),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView({required this.language, required this.analytics});

  final String language;
  final IAnalyticsService analytics;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouterFactory(
      sessionCubit: context.read<SessionCubit>(),
      observers: [
        AnalyticsRouteObserver(widget.analytics),
        // Sentry breadcrumbs from navigation. Only meaningful when the
        // Sentry SDK was initialized in bootstrap (production + DSN);
        // outside that window the observer is harmless overhead.
        if (ProfileConstants.sentryDsn != null) SentryNavigatorObserver(),
      ],
    ).create();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return WebBackButtonDisabler(
          child: MaterialApp.router(
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
          ),
        );
      },
    );
  }
}
