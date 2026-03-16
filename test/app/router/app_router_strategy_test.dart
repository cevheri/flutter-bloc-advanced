import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/router/app_router_strategy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../test_utils.dart';

void main() {
  final testUtils = TestUtils();

  setUp(() async {
    await testUtils.setupUnitTest();
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

  group('RouterType enum', () {
    test('has navigator value', () {
      expect(RouterType.navigator, isNotNull);
    });

    test('has goRouter value', () {
      expect(RouterType.goRouter, isNotNull);
    });

    test('has exactly 2 values', () {
      expect(RouterType.values.length, 2);
    });
  });

  group('AppRouter singleton', () {
    test('factory returns same instance', () {
      final a = AppRouter();
      final b = AppRouter();
      expect(identical(a, b), isTrue);
    });

    test('default strategy is GoRouterStrategy', () {
      // reset to goRouter in case previous tests changed it
      AppRouter().setRouter(RouterType.goRouter);
      expect(AppRouter().routeStrategy, isA<GoRouterStrategy>());
    });

    test('setRouter to navigator changes strategy', () {
      AppRouter().setRouter(RouterType.navigator);
      expect(AppRouter().routeStrategy, isA<NavigatorStrategy>());
    });

    test('setRouter to goRouter changes strategy', () {
      AppRouter().setRouter(RouterType.navigator);
      AppRouter().setRouter(RouterType.goRouter);
      expect(AppRouter().routeStrategy, isA<GoRouterStrategy>());
    });
  });

  group('NavigatorStrategy', () {
    late NavigatorStrategy strategy;

    setUp(() {
      strategy = NavigatorStrategy();
    });

    test('implements RouterStrategy', () {
      expect(strategy, isA<RouterStrategy>());
    });

    testWidgets('pop calls Navigator.pop', (tester) async {
      var didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: const Text('First'),
          routes: {
            '/second': (_) => Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    await strategy.pop(context);
                    didPop = true;
                  },
                  child: const Text('Pop'),
                );
              },
            ),
          },
        ),
      );

      // Navigate to /second first
      final context = tester.element(find.text('First'));
      Navigator.of(context).pushNamed('/second');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pop'));
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
      expect(find.text('First'), findsOneWidget);
    });

    testWidgets('push calls Navigator.pushNamed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) =>
                TextButton(onPressed: () => strategy.push(context, '/target'), child: const Text('Push')),
          ),
          routes: {'/target': (_) => const Text('Target Page')},
        ),
      );

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(find.text('Target Page'), findsOneWidget);
    });

    testWidgets('pushReplacement calls Navigator.pushReplacementNamed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => strategy.pushReplacement(context, '/replacement'),
              child: const Text('Replace'),
            ),
          ),
          routes: {'/replacement': (_) => const Text('Replacement Page')},
        ),
      );

      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();

      expect(find.text('Replacement Page'), findsOneWidget);
    });

    testWidgets('pushRemoveUntil calls Navigator.pushNamedAndRemoveUntil', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/middle');
              },
              child: const Text('Go Middle'),
            ),
          ),
          routes: {
            '/middle': (_) => Builder(
              builder: (context) => TextButton(
                onPressed: () => strategy.pushRemoveUntil(context, '/final'),
                child: const Text('Remove Until'),
              ),
            ),
            '/final': (_) => const Text('Final Page'),
          },
        ),
      );

      await tester.tap(find.text('Go Middle'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove Until'));
      await tester.pumpAndSettle();

      expect(find.text('Final Page'), findsOneWidget);
    });
  });

  group('GoRouterStrategy', () {
    late GoRouterStrategy strategy;

    setUp(() {
      strategy = GoRouterStrategy();
    });

    test('implements RouterStrategy', () {
      expect(strategy, isA<RouterStrategy>());
    });

    Widget buildGoRouterApp({required Widget home, Map<String, WidgetBuilder>? extraRoutes}) {
      final routes = <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(path: '/target', builder: (_, _) => const Text('Target Page')),
        GoRoute(path: '/replacement', builder: (_, _) => const Text('Replacement Page')),
        GoRoute(path: '/final', builder: (_, _) => const Text('Final Page')),
        GoRoute(
          path: '/named',
          name: 'named-route',
          builder: (_, state) => Text('Named: ${state.uri.queryParameters['q'] ?? 'none'}'),
        ),
      ];

      final router = GoRouter(initialLocation: '/', routes: routes);
      return MaterialApp.router(routerConfig: router);
    }

    testWidgets('push navigates with go', (tester) async {
      await tester.pumpWidget(
        buildGoRouterApp(
          home: Builder(
            builder: (context) =>
                TextButton(onPressed: () => strategy.push(context, '/target'), child: const Text('Push')),
          ),
        ),
      );

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(find.text('Target Page'), findsOneWidget);
    });

    testWidgets('push with args passes extra', (tester) async {
      late Object? capturedExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () => strategy.push(context, '/detail', args: {'id': 42}),
                child: const Text('Push with args'),
              ),
            ),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, state) {
              capturedExtra = state.extra;
              return const Text('Detail');
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Push with args'));
      await tester.pumpAndSettle();

      expect(find.text('Detail'), findsOneWidget);
      expect(capturedExtra, {'id': 42});
    });

    testWidgets('push with args and kwargs uses goNamed', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    strategy.push(context, 'named-route', args: <String, String>{}, kwargs: {'q': 'hello'}),
                child: const Text('Push Named'),
              ),
            ),
          ),
          GoRoute(
            path: '/named',
            name: 'named-route',
            builder: (_, state) => Text('Named: ${state.uri.queryParameters['q'] ?? 'none'}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Push Named'));
      await tester.pumpAndSettle();

      expect(find.text('Named: hello'), findsOneWidget);
    });

    testWidgets('pushReplacement navigates with go', (tester) async {
      await tester.pumpWidget(
        buildGoRouterApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => strategy.pushReplacement(context, '/replacement'),
              child: const Text('Replace'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();

      expect(find.text('Replacement Page'), findsOneWidget);
    });

    testWidgets('pushRemoveUntil navigates with go', (tester) async {
      await tester.pumpWidget(
        buildGoRouterApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => strategy.pushRemoveUntil(context, '/final'),
              child: const Text('Remove Until'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Remove Until'));
      await tester.pumpAndSettle();

      expect(find.text('Final Page'), findsOneWidget);
    });

    testWidgets('pushReplacement with args passes extra', (tester) async {
      late Object? capturedExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () => strategy.pushReplacement(context, '/detail', args: 'data'),
                child: const Text('Replace with args'),
              ),
            ),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, state) {
              capturedExtra = state.extra;
              return const Text('Detail');
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Replace with args'));
      await tester.pumpAndSettle();

      expect(capturedExtra, 'data');
    });

    testWidgets('pushRemoveUntil with args passes extra', (tester) async {
      late Object? capturedExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () => strategy.pushRemoveUntil(context, '/detail', args: 'remove-data'),
                child: const Text('Remove with args'),
              ),
            ),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, state) {
              capturedExtra = state.extra;
              return const Text('Detail');
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Remove with args'));
      await tester.pumpAndSettle();

      expect(capturedExtra, 'remove-data');
    });

    testWidgets('pushRemoveUntil with args and kwargs uses goNamed', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () => strategy.pushRemoveUntil(
                  context,
                  'named-route',
                  args: <String, String>{},
                  kwargs: {'q': 'remove-named'},
                ),
                child: const Text('Remove Named'),
              ),
            ),
          ),
          GoRoute(
            path: '/named',
            name: 'named-route',
            builder: (_, state) => Text('Named: ${state.uri.queryParameters['q'] ?? 'none'}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Remove Named'));
      await tester.pumpAndSettle();

      expect(find.text('Named: remove-named'), findsOneWidget);
    });

    testWidgets('pushReplacement with args and kwargs uses goNamed', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () => strategy.pushReplacement(
                  context,
                  'named-route',
                  args: <String, String>{},
                  kwargs: {'q': 'replace-named'},
                ),
                child: const Text('Replace Named'),
              ),
            ),
          ),
          GoRoute(
            path: '/named',
            name: 'named-route',
            builder: (_, state) => Text('Named: ${state.uri.queryParameters['q'] ?? 'none'}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Replace Named'));
      await tester.pumpAndSettle();

      expect(find.text('Named: replace-named'), findsOneWidget);
    });
  });

  group('AppRouter delegation', () {
    testWidgets('AppRouter.push delegates to current strategy', (tester) async {
      final appRouter = AppRouter();
      appRouter.setRouter(RouterType.goRouter);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () => appRouter.push(context, '/target'),
                child: const Text('Push via AppRouter'),
              ),
            ),
          ),
          GoRoute(path: '/target', builder: (_, _) => const Text('Target')),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Push via AppRouter'));
      await tester.pumpAndSettle();

      expect(find.text('Target'), findsOneWidget);
    });

    testWidgets('AppRouter.pushReplacement delegates to current strategy', (tester) async {
      final appRouter = AppRouter();
      appRouter.setRouter(RouterType.goRouter);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () => appRouter.pushReplacement(context, '/replaced'),
                child: const Text('Replace via AppRouter'),
              ),
            ),
          ),
          GoRoute(path: '/replaced', builder: (_, _) => const Text('Replaced')),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Replace via AppRouter'));
      await tester.pumpAndSettle();

      expect(find.text('Replaced'), findsOneWidget);
    });

    testWidgets('AppRouter.pushRemoveUntil delegates to current strategy', (tester) async {
      final appRouter = AppRouter();
      appRouter.setRouter(RouterType.goRouter);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () => appRouter.pushRemoveUntil(context, '/cleared'),
                child: const Text('Clear via AppRouter'),
              ),
            ),
          ),
          GoRoute(path: '/cleared', builder: (_, _) => const Text('Cleared')),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Clear via AppRouter'));
      await tester.pumpAndSettle();

      expect(find.text('Cleared'), findsOneWidget);
    });

    testWidgets('AppRouter.pop delegates to current strategy', (tester) async {
      final appRouter = AppRouter();
      appRouter.setRouter(RouterType.goRouter);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Text('Home'),
            routes: [
              GoRoute(
                path: 'child',
                builder: (_, _) => Builder(
                  builder: (context) =>
                      TextButton(onPressed: () => appRouter.pop(context), child: const Text('Pop via AppRouter')),
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/child');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pop via AppRouter'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('AppRouter with kwargs passes query parameters', (tester) async {
      final appRouter = AppRouter();
      appRouter.setRouter(RouterType.goRouter);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () => appRouter.push(context, 'search', args: <String, String>{}, kwargs: {'q': 'flutter'}),
                child: const Text('Search'),
              ),
            ),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (_, state) => Text('Query: ${state.uri.queryParameters['q'] ?? 'empty'}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.text('Query: flutter'), findsOneWidget);
    });
  });
}
