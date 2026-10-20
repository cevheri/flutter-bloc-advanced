@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_widget.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/account/presentation/pages/account_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_editor_page.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_list_page.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/test_env.dart';
import '../../../support/url_launcher_stub.dart';

const _docs = 'https://docs.acme.example';

void main() {
  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;

  Finder inSidebar(String label) => find.descendant(of: find.byType(SidebarWidget), matching: find.text(label));

  // The real app, signed in as an admin, on the dashboard. An admin sees every menu entry and may open the user list.
  Future<void> pumpAdminOnDashboard(WidgetTester tester, {Size size = const Size(1600, 1600)}) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    TestEnv.authenticate();
    await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN']);

    await tester.pumpWidget(const App(language: 'en'));
    await tester.pumpAndSettle();
  }

  // The real app, signed in, on settings: the sidebar is the same on every shell page and settings has no loading
  // animation. The shell shows the account name in the top bar once the mock API answers after its 500 ms delay, so
  // let that land before the screen is compared. The build gives the documentation website [docs].
  Future<void> pumpAppOnSettings(WidgetTester tester, {Size size = const Size(1600, 1600), String docs = _docs}) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    TestEnv.authenticate();

    await tester.pumpWidget(
      App(
        language: 'en',
        dependencies: AppDependencies(projectLinks: ProjectLinks(docs: docs)),
      ),
    );
    await tester.pump();
    (tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter).go(
      ApplicationRoutesConstants.settings,
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  group('SidebarWidget - website link that does not open', () {
    for (final failure in UrlLauncherFailure.values) {
      testWidgets('tapping Website shows a message when ${failure.description}', (tester) async {
        final calls = stubFailingUrlLauncher(failure);
        await pumpAppOnSettings(tester);

        await expectTapShowsMessage(tester, find.byKey(sidebarWebsiteButtonKey));
        expect(calls.requestedUrls, contains(_docs));
      });
    }
  });

  // On a phone the sidebar sits in the shell's drawer, which covers the snack bar that reports the failure.
  group('SidebarWidget - website link in the phone drawer', () {
    testWidgets('closes the drawer so the user sees that the link did not open', (tester) async {
      stubFailingUrlLauncher(UrlLauncherFailure.values.first);
      await pumpAppOnSettings(tester, size: const Size(390, 844));
      tester.state<ScaffoldState>(find.byWidgetPredicate((w) => w is Scaffold && w.drawer != null)).openDrawer();
      await tester.pumpAndSettle();

      await expectTapShowsMessage(tester, find.byKey(sidebarWebsiteButtonKey));
    });
  });

  group('SidebarWidget - website link that opens', () {
    for (final canLaunch in [true, false]) {
      testWidgets('tapping Website opens it and shows no message when canLaunchUrl answers $canLaunch', (tester) async {
        final calls = stubOpeningUrlLauncher(canLaunch: canLaunch);
        await pumpAppOnSettings(tester);

        await expectTapShowsNoMessage(tester, find.byKey(sidebarWebsiteButtonKey));
        expect(calls.launchedUrls, [_docs]);
      });
    }
  });

  group('SidebarWidget - project without a documentation website', () {
    // A made-up key: replacing the template's real placeholders across a project leaves this test as it is.
    testWidgets('shows no Website link while the docs URL is a placeholder', (tester) async {
      await pumpAppOnSettings(tester, docs: '__DOCS__');

      expect(find.byKey(sidebarWebsiteButtonKey), findsNothing);
      expect(find.text('Website'), findsNothing);
    });
  });

  group('SidebarWidget - navigation', () {
    for (final (label, location, page) in const [
      ('Account', ApplicationRoutesConstants.account, AccountScreen),
      ('Settings', ApplicationRoutesConstants.settings, SettingsScreen),
    ]) {
      testWidgets('tapping $label opens $location in place of the dashboard', (tester) async {
        await pumpAdminOnDashboard(tester);

        await tester.tap(inSidebar(label));
        await tester.pumpAndSettle();

        expect(routerOf(tester).state.uri.path, location);
        expect(find.byType(page), findsOneWidget);
        expect(routerOf(tester).canPop(), isFalse, reason: 'a menu entry replaces the page instead of stacking on it');
      });
    }

    for (final (label, location, page) in const [
      ('List', ApplicationRoutesConstants.userList, ListUserScreen),
      ('New', ApplicationRoutesConstants.userNew, UserEditorScreen),
    ]) {
      testWidgets('tapping $label under User Management opens $location', (tester) async {
        await pumpAdminOnDashboard(tester);
        await tester.tap(inSidebar('User Management'));
        await tester.pumpAndSettle();

        await tester.tap(inSidebar(label));
        await tester.pumpAndSettle();

        expect(routerOf(tester).state.uri.path, location);
        expect(find.byType(page), findsOneWidget);
        expect(routerOf(tester).canPop(), isFalse, reason: 'a menu entry replaces the page instead of stacking on it');
      });
    }

    testWidgets('tapping Settings in the phone drawer closes the drawer and opens /settings', (tester) async {
      await pumpAdminOnDashboard(tester, size: const Size(390, 844));
      final scaffold = tester.state<ScaffoldState>(find.byWidgetPredicate((w) => w is Scaffold && w.drawer != null));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(inSidebar('Settings'));
      await tester.pumpAndSettle();

      expect(routerOf(tester).state.uri.path, ApplicationRoutesConstants.settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(scaffold.isDrawerOpen, isFalse);
    });

    testWidgets('Logout signs the user out and opens the login page with no signed-in page to go back to', (
      tester,
    ) async {
      await pumpAdminOnDashboard(tester);

      await tester.tap(inSidebar('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Yes'));
      await tester.pumpAndSettle();

      expect(routerOf(tester).state.uri.path, ApplicationRoutesConstants.login);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(routerOf(tester).canPop(), isFalse);
    });
  });

  group('SidebarWidget - collapse across launches', () {
    double sidebarWidth(WidgetTester tester) => tester.getSize(find.byType(SidebarWidget)).width;

    // A relaunch mounts a new App, which reads the stored preferences again. Returns the sidebar's width in the first
    // frame that shows it.
    Future<double> relaunchAndMeasureFirstFrame(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const App(language: 'en'));
      for (var frame = 0; frame < 100 && find.byType(SidebarWidget).evaluate().isEmpty; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final width = sidebarWidth(tester);
      await tester.pumpAndSettle();
      return width;
    }

    testWidgets('a sidebar the user collapsed opens collapsed on the next launch', (tester) async {
      await pumpAdminOnDashboard(tester);
      await tester.tap(inSidebar('Collapse'));
      await tester.pumpAndSettle();
      expect(sidebarWidth(tester), AppBreakpoints.sidebarCollapsed);

      final firstFrameWidth = await relaunchAndMeasureFirstFrame(tester);

      expect(
        firstFrameWidth,
        AppBreakpoints.sidebarCollapsed,
        reason: 'collapsed from the start, not animating closed',
      );
      expect(sidebarWidth(tester), AppBreakpoints.sidebarCollapsed);
    });

    testWidgets('a sidebar the user collapsed and expanded again opens expanded on the next launch', (tester) async {
      await pumpAdminOnDashboard(tester);
      await tester.tap(inSidebar('Collapse'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(SidebarWidget), matching: find.byIcon(Icons.chevron_right)));
      await tester.pumpAndSettle();
      expect(sidebarWidth(tester), AppBreakpoints.sidebarExpanded);

      final firstFrameWidth = await relaunchAndMeasureFirstFrame(tester);

      expect(firstFrameWidth, AppBreakpoints.sidebarExpanded);
      expect(sidebarWidth(tester), AppBreakpoints.sidebarExpanded);
    });

    testWidgets('a sidebar the tablet layout collapsed on its own opens expanded on a later desktop launch', (
      tester,
    ) async {
      await pumpAdminOnDashboard(tester, size: const Size(900, 1600));
      expect(sidebarWidth(tester), AppBreakpoints.sidebarCollapsed);

      tester.view.physicalSize = const Size(1600, 1600);
      final firstFrameWidth = await relaunchAndMeasureFirstFrame(tester);

      expect(firstFrameWidth, AppBreakpoints.sidebarExpanded);
      expect(sidebarWidth(tester), AppBreakpoints.sidebarExpanded);
    });
  });
}
