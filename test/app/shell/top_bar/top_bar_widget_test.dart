@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_bloc_advance/features/account/presentation/pages/account_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/test_env.dart';

void main() {
  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;

  // The real app, signed in, on the dashboard, after the mock API has answered.
  Future<void> pumpSignedInOnDashboard(WidgetTester tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    TestEnv.authenticate();

    await tester.pumpWidget(const App(language: 'en'));
    await tester.pumpAndSettle();
  }

  Future<void> selectFromUserMenu(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: find.byType(TopBarWidget), matching: find.byType(PopupMenuButton<String>)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, label));
    await tester.pumpAndSettle();
  }

  group('TopBarWidget - user menu', () {
    for (final (label, location, page) in const [
      ('Account', ApplicationRoutesConstants.account, AccountScreen),
      ('Settings', ApplicationRoutesConstants.settings, SettingsScreen),
    ]) {
      testWidgets('$label opens $location in place of the dashboard', (tester) async {
        await pumpSignedInOnDashboard(tester);

        await selectFromUserMenu(tester, label);

        expect(routerOf(tester).state.uri.path, location);
        expect(find.byType(page), findsOneWidget);
        expect(routerOf(tester).canPop(), isFalse, reason: 'a menu entry replaces the page instead of stacking on it');
      });
    }

    testWidgets('Logout signs the user out and opens the login page with no signed-in page to go back to', (
      tester,
    ) async {
      await pumpSignedInOnDashboard(tester);

      await selectFromUserMenu(tester, 'Logout');
      await tester.tap(find.widgetWithText(FilledButton, 'Yes'));
      await tester.pumpAndSettle();

      expect(routerOf(tester).state.uri.path, ApplicationRoutesConstants.login);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(routerOf(tester).canPop(), isFalse);
    });
  });
}
