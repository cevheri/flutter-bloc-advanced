@Tags(['widget'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/account/presentation/pages/account_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../mocks/mock_classes.dart';
import '../../../support/test_env.dart';

void main() {
  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;

  // The real app, signed in, on the dashboard, after the mock API has answered.
  Future<void> pumpSignedInOnDashboard(WidgetTester tester, {Size size = const Size(1600, 1600)}) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = size;
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

  group('TopBarWidget - phone width', () {
    Finder userMenu() => find.descendant(of: find.byType(TopBarWidget), matching: find.byType(PopupMenuButton<String>));

    // Small phones, narrowest first. At 320 px the bar overflowed by 4.3 px with the dashboard title and the mock
    // account's name.
    for (final size in const [Size(320, 568), Size(360, 640), Size(375, 667)]) {
      testWidgets('the signed-in top bar fits a ${size.width.toInt()}x${size.height.toInt()} phone', (tester) async {
        await pumpSignedInOnDashboard(tester, size: size);

        expect(tester.takeException(), isNull);
        expect(tester.getRect(userMenu()).right, lessThanOrEqualTo(tester.getRect(find.byType(TopBarWidget)).right));
        expect(find.descendant(of: find.byType(TopBarWidget), matching: find.text('Admin')), findsOneWidget);
      });
    }

    // A screen reader user has to know what the bare menu icon does, in the language of the app.
    for (final (language, label) in const [('en', 'Open navigation menu'), ('tr', 'Gezinme menüsünü aç')]) {
      testWidgets('the menu button is announced as "$label" in $language', (tester) async {
        final semantics = tester.ensureSemantics();
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        TestEnv.authenticate();

        await tester.pumpWidget(App(language: language));
        await tester.pumpAndSettle();

        final button = find.descendant(of: find.byType(TopBarWidget), matching: find.byType(IconButton));
        expect(tester.getSemantics(button), isSemantics(tooltip: label, isButton: true, hasTapAction: true));
        semantics.dispose();
      });
    }

    // A page title and a first name much longer than the dashboard's and the mock account's, on the narrowest phone.
    testWidgets('a long page title and a long name are shortened instead of overflowing a 320 px bar', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      final accountBloc = MockAccountBloc();
      whenListen(
        accountBloc,
        const Stream<AccountState>.empty(),
        initialState: const AccountState(
          data: UserEntity(firstName: 'Maximiliano Alejandro', lastName: 'Montgomery'),
          status: AccountStatus.success,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AccountBloc>.value(
            value: accountBloc,
            child: Scaffold(
              body: TopBarWidget(title: 'Change-password', onMenuTap: () {}),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getRect(userMenu()).right, lessThanOrEqualTo(320));
      expect(find.text('Change-password'), findsOneWidget);
      expect(find.text('Maximiliano Alejandro'), findsOneWidget);
    });
  });

  // Without a page title the bar shows the breadcrumb, as on tablets and desktops, and has room for the whole name.
  group('TopBarWidget - user name beside the breadcrumb', () {
    testWidgets('a long name is shown in full', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      final accountBloc = MockAccountBloc();
      whenListen(
        accountBloc,
        const Stream<AccountState>.empty(),
        initialState: const AccountState(
          data: UserEntity(firstName: 'Maximiliano Alejandro', lastName: 'Montgomery'),
          status: AccountStatus.success,
        ),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => BlocProvider<AccountBloc>.value(
              value: accountBloc,
              child: const Scaffold(body: TopBarWidget()),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final name = tester.renderObject<RenderParagraph>(find.text('Maximiliano Alejandro'));
      expect(name.didExceedMaxLines, isFalse);
      expect(name.size.width, greaterThan(120));
    });
  });
}
