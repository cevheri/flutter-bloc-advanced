@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/analytics/analytics_route_observer.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Accepts every envelope without sending it, so nothing a test captures leaves the machine.
class _NoOpTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => null;
}

void main() {
  late List<Breadcrumb> breadcrumbs;

  setUp(() async {
    breadcrumbs = [];
    await Sentry.init((options) {
      options.dsn = 'https://public@example.invalid/1';
      options.transport = _NoOpTransport();
      options.beforeBreadcrumb = (breadcrumb, hint) {
        if (breadcrumb != null) breadcrumbs.add(breadcrumb);
        return breadcrumb;
      };
    });
    addTearDown(Sentry.close);
  });

  group('SentryAnalyticsService', () {
    // The app installs both observers when a Sentry DSN is set: AnalyticsRouteObserver over this service, and
    // SentryNavigatorObserver. Every breadcrumb counts against Sentry's buffer of the last 100.
    testWidgets('records a screen view as one navigation breadcrumb', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        observers: [AnalyticsRouteObserver(SentryAnalyticsService()), SentryNavigatorObserver()],
        routes: [
          GoRoute(name: 'home', path: '/', builder: (context, state) => const Text('home')),
          GoRoute(name: 'settings', path: '/settings', builder: (context, state) => const Text('settings')),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      breadcrumbs.clear();

      router.go('/settings');
      await tester.pumpAndSettle();

      expect(breadcrumbs.map((b) => (b.category, b.data?['to'])), [('navigation', 'settings')]);
    });
  });
}
