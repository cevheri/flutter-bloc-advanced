@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_home_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_list_page.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/test_env.dart';

void main() {
  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;

  Finder inBottomNav(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

  // The real app on a phone, where the shell shows the bottom navigation bar, signed in as an admin, who may open the
  // user list, on [location].
  Future<void> pumpAdminOnPhone(WidgetTester tester, {String location = ApplicationRoutesConstants.home}) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    TestEnv.authenticate();
    await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN']);

    await tester.pumpWidget(const App(language: 'en'));
    await tester.pumpAndSettle();
    routerOf(tester).go(location);
    await tester.pumpAndSettle();
  }

  group('BottomNavWidget', () {
    for (final (label, location, page) in const [
      ('List User', ApplicationRoutesConstants.userList, ListUserScreen),
      ('Settings', ApplicationRoutesConstants.settings, SettingsScreen),
    ]) {
      testWidgets('tapping $label opens $location in place of the dashboard', (tester) async {
        await pumpAdminOnPhone(tester);

        await tester.tap(inBottomNav(label));
        await tester.pumpAndSettle();

        expect(routerOf(tester).state.uri.path, location);
        expect(find.byType(page), findsOneWidget);
        expect(routerOf(tester).canPop(), isFalse, reason: 'a destination replaces the page instead of stacking on it');
      });
    }

    testWidgets('tapping Dashboard opens / in place of settings', (tester) async {
      await pumpAdminOnPhone(tester, location: ApplicationRoutesConstants.settings);

      await tester.tap(inBottomNav('Dashboard'));
      await tester.pumpAndSettle();

      expect(routerOf(tester).state.uri.path, ApplicationRoutesConstants.home);
      expect(find.byType(DashboardHomePage), findsOneWidget);
      expect(routerOf(tester).canPop(), isFalse, reason: 'a destination replaces the page instead of stacking on it');
    });
  });
}
