import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../test_utils.dart';

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  group('App Widget Tests', () {
    late App app;

    setUp(() {
      app = const App(language: 'tr', initialTheme: AdaptiveThemeMode.light);
    });

    testWidgets('App should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      expect(find.byType(AdaptiveTheme), findsOneWidget);
    });

    testWidgets('App should handle theme changes', (WidgetTester tester) async {
      await tester.pumpWidget(app);

      final AdaptiveTheme adaptiveTheme = tester.widget(find.byType(AdaptiveTheme));
      expect(adaptiveTheme.initial, equals(AdaptiveThemeMode.light));

      // Test dark theme
      app = const App(language: 'tr', initialTheme: AdaptiveThemeMode.dark);
      await tester.pumpWidget(app);

      final AdaptiveTheme darkTheme = tester.widget(find.byType(AdaptiveTheme));
      expect(darkTheme.initial, equals(AdaptiveThemeMode.dark));
    });

    testWidgets('App should handle different languages', (WidgetTester tester) async {
      app = const App(
        language: 'en',
        initialTheme: AdaptiveThemeMode.light,
      );
      await tester.pumpWidget(app);

      final GetMaterialApp materialApp = tester.widget(find.byType(GetMaterialApp));
      expect(materialApp.locale, equals(const Locale('en')));
    });

    testWidgets('MultiBlocProvider should contain all required providers', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      expect(find.byType(MultiBlocProvider), findsOneWidget);
    });
  });
}
