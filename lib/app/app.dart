import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_session_listeners.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/di/app_scope.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/app/router/app_router.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/web_back_button_disabler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({super.key, required this.language, this.dependencies = const AppDependencies()});

  final String language;
  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: AppSessionListeners(child: _AppView(language: language)),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView({required this.language});

  final String language;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouterFactory(sessionCubit: context.read<SessionCubit>()).create();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final currentTheme = themeState.isDarkMode
            ? AppTheme.dark(themeState.palette)
            : AppTheme.light(themeState.palette);

        return WebBackButtonDisabler(
          child: MaterialApp.router(
            theme: currentTheme,
            darkTheme: AppTheme.dark(themeState.palette),
            themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
