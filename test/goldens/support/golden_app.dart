import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

/// Standard phone surface for screen goldens.
const Size kGoldenScreenSize = Size(390, 844);
