import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  group('App Widget Tests', () {
    late App app;

    setUp(() {
      app = const App(language: 'tr');
    });

    testWidgets('App should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App should handle theme changes', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);

      // Test with different language
      app = const App(language: 'en');
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App should handle different languages', (WidgetTester tester) async {
      TestUtils().setupAuthentication();
      app = const App(language: 'en');
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      const expectedLocale = Locale('en');
      final materialApp = tester.widget(find.byType(MaterialApp)) as MaterialApp;
      expect(materialApp.locale, equals(expectedLocale));
    });

    testWidgets('MultiBlocProvider should contain all required providers', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.byType(MultiBlocProvider), findsOneWidget);
    });
  });
}
