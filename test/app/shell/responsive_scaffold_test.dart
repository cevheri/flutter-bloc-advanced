@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_widget.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_env.dart';

void main() {
  // The real app, signed in, on the dashboard, on a device whose system bars cover [insets] of the screen.
  Future<void> pumpSignedIn(WidgetTester tester, {required Size size, required FakeViewPadding insets}) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = insets;
    tester.view.viewPadding = insets;
    TestEnv.authenticate();

    await tester.pumpWidget(const App(language: 'en'));
    await tester.pumpAndSettle();
    expect(find.byType(ResponsiveScaffold), findsOneWidget);
  }

  Finder menuButton() => find.descendant(of: find.byType(TopBarWidget), matching: find.byIcon(Icons.menu));

  // An Android phone with a 48 px status bar, as on an API 36 emulator.
  const statusBar = FakeViewPadding(top: 48);

  group('ResponsiveScaffold - status bar', () {
    testWidgets('the phone top bar starts below the status bar and its menu button takes a tap at its top', (
      tester,
    ) async {
      await pumpSignedIn(tester, size: const Size(412, 915), insets: statusBar);

      expect(tester.getRect(find.byType(TopBarWidget)).top, greaterThanOrEqualTo(48));
      final button = tester.getRect(menuButton());
      expect(button.top, greaterThanOrEqualTo(48));

      await tester.tapAt(Offset(button.center.dx, button.top + 2));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('the drawer header starts below the status bar', (tester) async {
      await pumpSignedIn(tester, size: const Size(412, 915), insets: statusBar);

      await tester.tap(menuButton());
      await tester.pumpAndSettle();

      final drawerSidebar = find.descendant(of: find.byType(Drawer), matching: find.byType(SidebarWidget));
      expect(tester.getRect(drawerSidebar).top, greaterThanOrEqualTo(48));
    });

    for (final (layout, size) in const [('tablet', Size(800, 1280)), ('desktop', Size(1280, 800))]) {
      testWidgets('the $layout sidebar header and top bar start below the status bar', (tester) async {
        await pumpSignedIn(tester, size: size, insets: statusBar);

        // The tablet collapses the sidebar to its icons, so the header is checked by the sidebar's own top edge.
        expect(tester.getRect(find.byType(SidebarWidget)).top, greaterThanOrEqualTo(48));
        expect(tester.getRect(find.byType(TopBarWidget)).top, greaterThanOrEqualTo(48));
      });
    }
  });

  group('ResponsiveScaffold - landscape side insets', () {
    // A phone turned on its side: the status bar is on top and the camera cutout and the navigation bar on the sides.
    const landscape = FakeViewPadding(left: 48, top: 24, right: 48);

    testWidgets('the sidebar and the top bar stay clear of the cutout and the navigation bar', (tester) async {
      await pumpSignedIn(tester, size: const Size(915, 412), insets: landscape);

      expect(tester.getRect(find.byType(SidebarWidget)).left, greaterThanOrEqualTo(48));
      final topBar = tester.getRect(find.byType(TopBarWidget));
      expect(topBar.top, greaterThanOrEqualTo(24));
      expect(topBar.right, lessThanOrEqualTo(915 - 48));
    });

    testWidgets('the phone top bar and the drawer stay clear of the side insets', (tester) async {
      await pumpSignedIn(tester, size: const Size(740, 360), insets: landscape);

      final topBar = tester.getRect(find.byType(TopBarWidget));
      expect(topBar.left, greaterThanOrEqualTo(48));
      expect(topBar.right, lessThanOrEqualTo(740 - 48));

      await tester.tap(menuButton());
      await tester.pumpAndSettle();

      final drawerSidebar = tester.getRect(
        find.descendant(of: find.byType(Drawer), matching: find.byType(SidebarWidget)),
      );
      expect(drawerSidebar.left, greaterThanOrEqualTo(48));
      expect(drawerSidebar.top, greaterThanOrEqualTo(24));
    });
  });

  // The real app, signed in as an admin on a phone, where the top bar shows the page title instead of the breadcrumb.
  Future<void> pumpPhoneOn(WidgetTester tester, String location, {required String language}) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    TestEnv.authenticate();
    await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN']);

    await tester.pumpWidget(App(language: language));
    await tester.pumpAndSettle();
    (tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter).go(location);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Finder titleInTopBar(String title) => find.descendant(of: find.byType(TopBarWidget), matching: find.text(title));

  group('ResponsiveScaffold - phone page title', () {
    for (final (location, title) in const [
      (ApplicationRoutesConstants.settings, 'Ayarlar'),
      (ApplicationRoutesConstants.changePassword, 'Şifre Değiştir'),
      (ApplicationRoutesConstants.userList, 'Kullanıcılar'),
    ]) {
      testWidgets('shows $title for $location in Turkish', (tester) async {
        await pumpPhoneOn(tester, location, language: 'tr');

        expect(titleInTopBar(title), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows the page title of a route with a hyphen in English', (tester) async {
      await pumpPhoneOn(tester, ApplicationRoutesConstants.changePassword, language: 'en');

      expect(titleInTopBar('Change Password'), findsOneWidget);
    });
  });
}
