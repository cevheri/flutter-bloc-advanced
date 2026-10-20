@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_home_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../support/test_env.dart';

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

  // A deep link, a bookmarked URL or a browser refresh starts the app on this location: GoRouter prefers the
  // platform's default route over its initialLocation.
  void startOn(WidgetTester tester, String location) {
    tester.platformDispatcher.defaultRouteNameTestValue = location;
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
  }

  // Pumps the authenticated shell frame by frame and returns the frames that built the login page, offstage ones
  // included. The shell keeps animating (dashboard skeletons), so pumpAndSettle would time out there.
  Future<List<int>> pumpShellRecordingLogin(WidgetTester tester) async {
    final loginFrames = <int>[];
    for (var frame = 0; frame < 30; frame++) {
      if (find.byType(LoginScreen, skipOffstage: false).evaluate().isNotEmpty) loginFrames.add(frame);
      await tester.pump(const Duration(milliseconds: 100));
    }
    return loginFrames;
  }

  group('AppRouterFactory', () {
    testWidgets('redirects unauthenticated users to login', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      final router = routerFromApp(tester);
      router.go(ApplicationRoutesConstants.settings);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('allows authenticated users to open settings', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      final router = routerFromApp(tester);
      router.go(ApplicationRoutesConstants.settings);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('never builds the login page on an authenticated cold start', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      final analytics = MockAnalyticsService();
      await tester.pumpWidget(App(language: 'en', analytics: analytics));
      final loginFrames = await pumpShellRecordingLogin(tester);

      expect(loginFrames, isEmpty, reason: 'frames that built the login page');
      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.home);
      expect(find.byType(DashboardHomePage), findsOneWidget);
      verifyNever(
        () => analytics.logScreenView(
          screenName: any(named: 'screenName', that: equals('login')),
          screenClass: any(named: 'screenClass'),
        ),
      );
    });

    testWidgets('opens a deep link on an authenticated cold start', (tester) async {
      setDesktopViewport(tester);
      startOn(tester, ApplicationRoutesConstants.settings);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      final loginFrames = await pumpShellRecordingLogin(tester);

      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(loginFrames, isEmpty, reason: 'frames that built the login page');
    });

    testWidgets('keeps a deep link as the login returnUrl on an unauthenticated cold start', (tester) async {
      setDesktopViewport(tester);
      startOn(tester, ApplicationRoutesConstants.settings);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(routerFromApp(tester).state.uri.queryParameters['returnUrl'], ApplicationRoutesConstants.settings);
    });
  });
}
