import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/test_env.dart';

void main() {
  Widget buildTestableWidget() {
    final router = GoRouter(
      initialLocation: ApplicationRoutesConstants.settings,
      routes: [
        GoRoute(
          path: ApplicationRoutesConstants.settings,
          builder: (context, state) => const Scaffold(body: SettingsScreen()),
        ),
        GoRoute(
          path: ApplicationRoutesConstants.changePassword,
          builder: (context, state) => const Scaffold(body: Placeholder()),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    );
  }

  group('SettingsScreen Tests', () {
    testWidgets('renders all settings tiles', (WidgetTester tester) async {
      TestEnv.authenticate();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Assert via Keys only — text-based asserts would couple the
      // test to the active locale (some titles use S.of(context) /
      // generated strings, others are still literals pending i18n).
      // Key presence is enough to guard the screen layout against
      // accidental tile removal.
      expect(find.byKey(settingsChangePasswordButtonKey), findsOneWidget);
      expect(find.byKey(settingsWebsiteButtonKey), findsOneWidget);
      // Logout intentionally lives only in the sidebar / topbar shell —
      // settings does not own auth-session lifecycle (cross-feature).
    });

    testWidgets('navigates to change password screen when button is pressed', (WidgetTester tester) async {
      TestEnv.authenticate();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(settingsChangePasswordButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsNothing);
    });
  });
}
