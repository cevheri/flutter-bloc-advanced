@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/router/forbidden_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;

import '../../support/test_env.dart';

/// go_router 18 only recognizes material_ui's `MaterialApp`. Under the SDK `MaterialApp.router` used by this app, a
/// `builder:` route silently becomes a `NoTransitionPage` (no transition, no iOS back swipe) and an unknown location
/// renders go_router's unstyled widgets-only error screen. These tests pin the Material page behavior.
void main() {
  void setDesktopViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
  }

  GoRouter routerFromApp(WidgetTester tester) {
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    return materialApp.routerConfig! as GoRouter;
  }

  // The first Navigator in the tree is go_router's root navigator.
  List<Page<Object?>> rootPages(WidgetTester tester) => tester.widget<Navigator>(find.byType(Navigator).first).pages;

  group('AppRouterFactory pages', () {
    testWidgets('builds public routes as Material pages', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(rootPages(tester).last, isA<MaterialPage<void>>());
    });

    testWidgets('animates pushed public routes', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      routerFromApp(tester).push(ApplicationRoutesConstants.register);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final route = ModalRoute.of(tester.element(find.byType(RegisterScreen)))!;
      expect(route.transitionDuration, greaterThan(Duration.zero));
      expect(route.animation!.value, lessThan(1.0));

      await tester.pumpAndSettle();
      expect(rootPages(tester).last, isA<MaterialPage<void>>());
    });

    testWidgets('pops a pushed public route with the iOS back swipe', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      routerFromApp(tester).push(ApplicationRoutesConstants.register);
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      // A fast drag across 75% of the width, so the pop never hinges on the 50% threshold.
      await tester.timedDragFrom(const Offset(5, 400), const Offset(1200, 0), const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('keeps path parameters out of route arguments', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      // Route arguments end up in navigation breadcrumbs (SentryNavigatorObserver), and this path carries an email.
      routerFromApp(tester).go('${ApplicationRoutesConstants.loginOtpVerify}/jane.doe@example.com');
      await tester.pumpAndSettle();

      final page = rootPages(tester).last;
      expect(page, isA<MaterialPage<void>>());
      expect(page.arguments, isNull);
    });

    testWidgets('builds the authenticated shell as a Material page', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.home);
      expect(rootPages(tester).last, isA<MaterialPage<void>>());
    });

    testWidgets('builds the forbidden route as a Material page', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      routerFromApp(tester).go(ApplicationRoutesConstants.userList);
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
      expect(rootPages(tester).last, isA<MaterialPage<void>>());
    });

    // go_router 18.1.0 gave both shell pages the same page key and failed the Navigator assertion
    // '!keyReservation.contains(key)' (flutter/flutter#140586, fixed in 18.1.1).
    testWidgets('pushes a shell route over a root route pushed over the shell', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      routerFromApp(tester).push(ApplicationRoutesConstants.forbidden);
      await tester.pumpAndSettle();
      expect(find.byType(ForbiddenPage), findsOneWidget);

      routerFromApp(tester).push(ApplicationRoutesConstants.settings);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.settings);
    });

    testWidgets('renders a Material not-found page for unknown locations', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      routerFromApp(tester).go('/does-not-exist');
      await tester.pumpAndSettle();

      expect(rootPages(tester).last, isA<MaterialPage<void>>());
      expect(find.ancestor(of: find.text('Page Not Found'), matching: find.byType(Scaffold)), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Home'));
      await tester.pumpAndSettle();

      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.home);
    });

    testWidgets('shows the not-found page in Turkish', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'tr'));
      await tester.pumpAndSettle();

      routerFromApp(tester).go('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.text('Sayfa Bulunamadı'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Ana Sayfa'), findsOneWidget);
    });

    // The page showed go_router's error text, such as "GoException: no routes for location: /does-not-exist", in
    // English in every language.
    testWidgets('says that the page was not found and logs the location that matched no route', (tester) async {
      final warnings = <String>[];
      void record(OutputEvent event) {
        if (event.level == Level.warning) warnings.addAll(event.lines);
      }

      Logger.addOutputListener(record);
      addTearDown(() => Logger.removeOutputListener(record));
      setDesktopViewport(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'tr'));
      await tester.pumpAndSettle();

      routerFromApp(tester).go('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.text('İstediğiniz sayfa bulunamadı.'), findsOneWidget);
      expect(find.textContaining('GoException'), findsNothing);
      expect(warnings, contains(allOf(contains('/does-not-exist'), contains('no routes for location'))));
    });

    testWidgets('declares every route with a pageBuilder', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      void expectPageBuilder(RouteBase route) {
        if (route is GoRoute) {
          expect(
            route.builder,
            isNull,
            reason: 'GoRoute ${route.path} uses builder:, which go_router 18 renders as a NoTransitionPage',
          );
        } else if (route is ShellRoute) {
          expect(
            route.builder,
            isNull,
            reason: 'ShellRoute uses builder:, which go_router 18 renders as a NoTransitionPage',
          );
        } else if (route is StatefulShellRoute) {
          expect(
            route.builder,
            isNull,
            reason: 'StatefulShellRoute uses builder:, which go_router 18 renders as a NoTransitionPage',
          );
        }
        route.routes.forEach(expectPageBuilder);
      }

      routerFromApp(tester).configuration.routes.forEach(expectPageBuilder);
    });
  });
}
