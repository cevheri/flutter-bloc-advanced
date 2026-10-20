import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'unsaved_changes_host.dart';

/// Wraps a screen for golden capture: full localization, the app theme, and a
/// phone-sized surface. Pass the screen already wrapped in its BlocProviders
/// (with mock BLoCs seeded to a loaded state). Use `dark: true` for the dark
/// variant.
Widget goldenScreen(Widget screen, {bool dark = false}) => MaterialApp(
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
  home: screen,
);

/// [goldenScreen] for a page that must sit in a go_router page, such as a page with an `UnsavedChangesScope`.
Widget goldenRoutedScreen(Widget screen, {bool dark = false}) => withUnsavedChangesRegistry(
  MaterialApp.router(
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
    routerConfig: GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => screen)],
    ),
  ),
);

/// Standard phone surface for screen goldens.
const Size kGoldenScreenSize = Size(390, 844);

/// Pumps [widget] for an alchemist golden with the app's localizations, for a widget that reads `S.of(context)`.
/// Alchemist's own wrapper loads only the default Material, Widgets and Cupertino localizations. Pass it as
/// `goldenTest(pumpWidget: pumpWithLocalizations)`.
Future<void> pumpWithLocalizations(WidgetTester tester, Widget widget) => tester.pumpWidget(
  Localizations(
    locale: const Locale('en'),
    delegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    child: widget,
  ),
);
