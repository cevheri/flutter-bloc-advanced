import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../test_utils.dart';

void main() {
  late AppRouter router;

  setUp(() async {
    await TestUtils().setupUnitTest();
    router = AppRouter();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  Widget buildTestableWidget({required Widget child}) {
    final goRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => child),
        GoRoute(path: '/home', builder: (context, state) => const SizedBox()),
      ],
    );

    return MaterialApp.router(routerConfig: goRouter);
  }

  group('AppRouter Tests', () {
    testWidgets('Default router should be GoRouter', (tester) async {
      expect(router, isNotNull);
      expect(router.routeStrategy, isA<GoRouterStrategy>());
    });

    testWidgets('setRouter should change router strategy', (tester) async {
      router.setRouter(RouterType.navigator);
      expect(router.routeStrategy, isA<NavigatorStrategy>());

      router.setRouter(RouterType.goRouter);
      expect(router.routeStrategy, isA<GoRouterStrategy>());
    });

    group('Navigation Tests', () {
      testWidgets(skip: true, 'pop should call strategy pop', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (context) => TextButton(onPressed: () => router.pop(context), child: const Text('Pop')),
            ),
          ),
        );

        await tester.tap(find.text('Pop'));
        await tester.pumpAndSettle();
      });

      testWidgets('push should call strategy push', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => router.push(context, ApplicationRoutesConstants.home),
                child: const Text('Push'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Push'));
        await tester.pumpAndSettle();
      });

      testWidgets('pushReplacement should call strategy pushReplacement', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => router.pushReplacement(context, ApplicationRoutesConstants.home),
                child: const Text('Replace'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Replace'));
        await tester.pumpAndSettle();
      });
    });

    group('Error Handling Tests', () {
      testWidgets(skip: true, 'should handle invalid routes gracefully', (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (context) =>
                  TextButton(onPressed: () => router.push(context, '/invalid-route'), child: const Text('Invalid')),
            ),
          ),
        );

        await tester.tap(find.text('Invalid'));
        expect(tester.takeException(), isA<Exception>());
      });
    });
  });
}
