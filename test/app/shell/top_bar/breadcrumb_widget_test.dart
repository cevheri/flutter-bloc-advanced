@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/breadcrumb_widget.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Widget buildTestableWidget({required String initialLocation, Locale locale = const Locale('en')}) {
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

    return MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    );
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
      expect(find.text('Users'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders two segments for /user/new', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/new'));
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      // home chevron + segment chevron = 2
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('collapses /user/:id/view into two segments', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/test-user/view'));
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Test user'), findsOneWidget);
      // home chevron + 1 segment chevron = 2
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('renders three segments for /user/:id/edit', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/test-user/edit'));
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsOneWidget);
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

    testWidgets('clicking Users breadcrumb on /user/new navigates to /user', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/new'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      // Should be on /user now, only Users segment visible (non-navigable)
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('New'), findsNothing);
    });

    testWidgets('clicking Users breadcrumb on /user/:id/edit navigates to /user', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/test-user/edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('clicking id segment on /user/:id/edit navigates to view', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/test-user/edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test user'));
      await tester.pumpAndSettle();

      // Should be on /user/test-user/view now (collapsed to Users > Test user)
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Test user'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });
  });

  group('BreadcrumbWidget - Turkish', () {
    testWidgets('shows the route words and the home label in Turkish', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/user/new', locale: const Locale('tr')));
      await tester.pumpAndSettle();

      expect(find.text('Kullanıcılar'), findsOneWidget);
      expect(find.text('Yeni'), findsOneWidget);
      expect(find.bySemanticsLabel('Ana Sayfa'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('shows the dashboard in Turkish on the home route', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialLocation: '/', locale: const Locale('tr')));
      await tester.pumpAndSettle();

      expect(find.text('Panel'), findsOneWidget);
    });
  });
}
