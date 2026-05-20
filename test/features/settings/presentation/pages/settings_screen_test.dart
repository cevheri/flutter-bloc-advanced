import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../test_utils.dart';

void main() {
  late TestUtils testUtils;

  setUp(() async {
    testUtils = TestUtils();
    await testUtils.setupUnitTest();
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

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
      testUtils.setupAuthentication();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Each visible tile on the settings screen — keyed actions get
      // exact assertions, label-only tiles get text matches so the
      // screen layout is guarded against accidental removal.
      expect(find.byKey(settingsChangePasswordButtonKey), findsOneWidget);
      expect(find.byKey(settingsWebsiteButtonKey), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      // Logout intentionally lives only in the sidebar / topbar shell —
      // settings does not own auth-session lifecycle (cross-feature).
    });

    testWidgets('navigates to change password screen when button is pressed', (WidgetTester tester) async {
      testUtils.setupAuthentication();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(settingsChangePasswordButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsNothing);
    });
  });
}
