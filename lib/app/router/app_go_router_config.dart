import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/router/app_router.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

class ErrorScreen extends StatelessWidget {
  final GoException? error;

  const ErrorScreen(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${error?.message}'),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Go back')),
          ],
        ),
      ),
    );
  }
}

class AppGoRouterConfig {
  static GoRouter buildRouter(BuildContext context) {
    return AppRouterFactory(sessionCubit: context.read<SessionCubit>()).create();
  }

  static MaterialApp routeBuilder(ThemeData theme, ThemeData darkTheme, String language, ThemeMode themeMode) {
    final sessionCubit = SessionCubit()..restore();

    return MaterialApp.router(
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: true,
      debugShowMaterialGrid: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: Locale(language),
      routerConfig: AppRouterFactory(sessionCubit: sessionCubit).create(),
    );
  }
}
