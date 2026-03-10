import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/breadcrumb_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../test_utils.dart';

void main() {
  setUp(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  Widget buildTestableWidget({required String initialLocation}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Row(children: [const Expanded(child: BreadcrumbWidget())]),
            ),
            body: child,
          ),
          routes: [
            GoRoute(path: '/', builder: (context, state) => const SizedBox()),
            GoRoute(path: '/user', builder: (context, state) => const SizedBox()),
            GoRoute(path: '/user/new', builder: (context, state) => const SizedBox()),
            GoRoute(path: '/user/:id/view', builder: (context, state) => const SizedBox()),
            GoRoute(path: '/user/:id/edit', builder: (context, state) => const SizedBox()),
            GoRoute(path: '/account', builder: (context, state) => const SizedBox()),
            GoRoute(path: '/settings', builder: (context, state) => const SizedBox()),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('BreadcrumbWidget', () {
    testWidgets('renders home icon on dashboard', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('renders home icon and single segment for /user', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders two segments for /user/new', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/new'));
      await tester.pumpAndSettle();

      expect(find.text('User'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      // home chevron + segment chevron = 2
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('collapses /user/:id/view into two segments', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/test-user/view'));
      await tester.pumpAndSettle();

      expect(find.text('User'), findsOneWidget);
      expect(find.text('Test user'), findsOneWidget);
      // home chevron + 1 segment chevron = 2
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('renders three segments for /user/:id/edit', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/test-user/edit'));
      await tester.pumpAndSettle();

      expect(find.text('User'), findsOneWidget);
      expect(find.text('Test user'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      // home chevron + 2 segment chevrons = 3
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    });

    testWidgets('clicking home icon navigates to /', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      // After navigating to /, breadcrumb should show Dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('clicking User breadcrumb on /user/new navigates to /user', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/new'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('User'));
      await tester.pumpAndSettle();

      // Should be on /user now, only User segment visible (non-navigable)
      expect(find.text('User'), findsOneWidget);
      expect(find.text('New'), findsNothing);
    });

    testWidgets('clicking User breadcrumb on /user/:id/edit navigates to /user', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/test-user/edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('User'));
      await tester.pumpAndSettle();

      expect(find.text('User'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('clicking id segment on /user/:id/edit navigates to view', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/test-user/edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test user'));
      await tester.pumpAndSettle();

      // Should be on /user/test-user/view now (collapsed to User > Test user)
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Test user'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });
  });
}
