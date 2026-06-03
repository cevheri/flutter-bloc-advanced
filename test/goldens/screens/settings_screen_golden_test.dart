import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_env.dart';
import '../support/golden_app.dart' show kGoldenScreenSize;

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  Widget buildScreen({bool dark = false}) {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: SettingsScreen()),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const Scaffold(body: Placeholder()),
        ),
        GoRoute(
          path: '/account',
          builder: (context, state) => const Scaffold(body: Placeholder()),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    );
  }

  goldenTest(
    'SettingsScreen — light',
    fileName: 'settings_screen_light',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: buildScreen(dark: false)),
        ),
      ],
    ),
  );

  goldenTest(
    'SettingsScreen — dark',
    fileName: 'settings_screen_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: buildScreen(dark: true)),
        ),
      ],
    ),
  );
}
