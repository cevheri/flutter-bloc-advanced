@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/dev_console/tabs/network_tab.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/logging_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    LoggingInterceptor.verbose = false;
    DevConsoleStore.instance.clearNetwork();
  });

  tearDown(() {
    LoggingInterceptor.verbose = false;
  });

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NetworkTab())));
  }

  group('NetworkTab verbose logging toggle', () {
    testWidgets('renders the toggle even when no requests captured', (tester) async {
      await pumpTab(tester);

      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Verbose logs'), findsOneWidget);
    });

    testWidgets('toggle reflects the current LoggingInterceptor.verbose value', (tester) async {
      LoggingInterceptor.verbose = true;
      await pumpTab(tester);

      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isTrue);
    });

    testWidgets('tapping the toggle flips LoggingInterceptor.verbose on then off', (tester) async {
      await pumpTab(tester);
      expect(LoggingInterceptor.verbose, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(LoggingInterceptor.verbose, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(LoggingInterceptor.verbose, isFalse);
    });
  });
}
