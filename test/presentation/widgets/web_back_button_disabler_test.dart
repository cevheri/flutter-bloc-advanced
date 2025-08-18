import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/web_back_button_disabler.dart';

void main() {
  group('WebBackButtonDisabler Tests', () {
    testWidgets('should render child widget correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: WebBackButtonDisabler(child: Text('Test Child Widget'))));

      expect(find.text('Test Child Widget'), findsOneWidget);
    });

    testWidgets('should render Scaffold child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WebBackButtonDisabler(child: Scaffold(body: Text('Scaffold Child'))),
        ),
      );

      expect(find.text('Scaffold Child'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should render Container child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WebBackButtonDisabler(
            child: Container(color: Colors.red, child: const Text('Container Child')),
          ),
        ),
      );

      expect(find.text('Container Child'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should preserve child widget key', (WidgetTester tester) async {
      const testKey = Key('test_key');

      await tester.pumpWidget(
        const MaterialApp(
          home: WebBackButtonDisabler(child: Text('Keyed Widget', key: testKey)),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
      expect(find.text('Keyed Widget'), findsOneWidget);
    });
  });
}
