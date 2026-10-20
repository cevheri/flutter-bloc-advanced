@Tags(['widget'])
library;

import 'dart:async';

import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_classes.dart';

void main() {
  group('App', () {
    testWidgets('shows a loading indicator in place of the router until the stored session is restored', (
      tester,
    ) async {
      final storedToken = Completer<String?>();
      final secureStorage = MockISecureStorage();
      when(() => secureStorage.read(any())).thenAnswer((_) => storedToken.future);
      final analytics = MockAnalyticsService();
      await tester.pumpWidget(App(language: 'en', secureStorage: secureStorage, analytics: analytics));
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('Loading...'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      verifyNever(
        () => analytics.logScreenView(
          screenName: any(named: 'screenName'),
          screenClass: any(named: 'screenClass'),
        ),
      );

      storedToken.complete(null);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Loading...'), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
