@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/router/forbidden_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
