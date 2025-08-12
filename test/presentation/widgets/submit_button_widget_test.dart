import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/submit_button_widget.dart';

void main() {
  group('ResponsiveSubmitButton Widget Tests', () {
    testWidgets('should render with default props', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ResponsiveSubmitButton())));

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should show loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ResponsiveSubmitButton(isLoading: true))));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Button should be disabled when loading
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, null);
    });

    testWidgets('should call onPressed when button is clicked', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ResponsiveSubmitButton(onPressed: () => wasPressed = true)),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('should use custom button text', (tester) async {
      const customText = 'Custom Button Text';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ResponsiveSubmitButton(buttonText: customText)),
        ),
      );

      expect(find.text(customText), findsOneWidget);
    });

    testWidgets('should align right on web platform', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ResponsiveSubmitButton(isWebPlatform: true))));

      final alignFinder = find.ancestor(of: find.byType(FilledButton), matching: find.byType(Align));

      expect(alignFinder, findsOneWidget);
      final align = tester.widget<Align>(alignFinder);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('should not align on mobile platform', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ResponsiveSubmitButton(isWebPlatform: false))));

      // FilledButton'ı içeren Align widget'ını kontrol et
      final alignFinder = find.ancestor(of: find.byType(FilledButton), matching: find.byType(Align));

      expect(alignFinder, findsNothing);
    });
  });

  group('ButtonContent Widget Tests', () {
    testWidgets('should render text correctly', (tester) async {
      const testText = 'Test Button';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ButtonContent(text: testText, isLoading: false)),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('should show loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ButtonContent(text: 'Test', isLoading: true)),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should use theme colors for loading indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light().copyWith(onPrimary: Colors.red)),
          home: const Scaffold(body: ButtonContent(text: 'Test', isLoading: true)),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));

      expect((progressIndicator.valueColor as AlwaysStoppedAnimation<Color>).value, Colors.red);
    });
  });
}
