import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../test_utils.dart';

void main() {
  final testUtils = TestUtils();

  void setDesktopViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
  }

  setUp(() async {
    await testUtils.setupUnitTest();
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

  GoRouter routerFromApp(WidgetTester tester) {
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    return materialApp.routerConfig! as GoRouter;
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
      await testUtils.setupAuthentication();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      final router = routerFromApp(tester);
      router.go(ApplicationRoutesConstants.settings);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
