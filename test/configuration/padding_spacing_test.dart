import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/padding_spacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Spacing', () {
    group('Constant values', () {
      test('Given constant values When accessed Then should return correct values', () {
        // Given & When & Then
        expect(Spacing.small, 8.0);
        expect(Spacing.medium, 16.0);
        expect(Spacing.large, 24.0);
      });

      test('Given form width constants When accessed Then should return correct values', () {
        // Given & When & Then
        expect(Spacing.formMaxWidthSmall, 200.0);
        expect(Spacing.formMaxWidthMedium, 400.0);
        expect(Spacing.formMaxWidthLarge, 600.0);
        expect(Spacing.formMaxWidthXLarge, 800.0);
      });
    });

    group('Height percentage calculations', () {
      testWidgets('Given context When height percentage methods called Then should calculate correct values', (
        WidgetTester tester,
      ) async {
        // Given
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final height = MediaQuery.of(context).size.height;

                // When & Then
                expect(Spacing.heightPercentage10(context), height * 0.1);
                expect(Spacing.heightPercentage50(context), height * 0.5);
                expect(Spacing.heightPercentage100(context), height);

                // Dynamic percentage test
                expect(Spacing.heightPercentage(context, 0.15), height * 0.15);
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('Given invalid context When height percentage methods called Then should throw exception', (
        WidgetTester tester,
      ) async {
        // Given
        BuildContext? invalidContext;

        // When & Then
        expect(() => Spacing.heightPercentage10(invalidContext!), throwsA(isA<TypeError>()));
        expect(() => Spacing.heightPercentage(invalidContext!, 0.5), throwsA(isA<TypeError>()));
      });
    });

    group('Width percentage calculations', () {
      testWidgets('Given context When width percentage methods called Then should calculate correct values', (
        WidgetTester tester,
      ) async {
        // Given
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final width = MediaQuery.of(context).size.width;

                // When & Then
                expect(Spacing.widthPercentage10(context), width * 0.1);
                expect(Spacing.widthPercentage50(context), width * 0.5);
                expect(Spacing.widthPercentage100(context), width);

                // Dynamic percentage test
                expect(Spacing.widthPercentage(context, 0.15), width * 0.15);
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('Given invalid context When width percentage methods called Then should throw exception', (
        WidgetTester tester,
      ) async {
        // Given
        BuildContext? invalidContext;

        // When & Then
        expect(() => Spacing.widthPercentage10(invalidContext!), throwsA(isA<TypeError>()));
        expect(() => Spacing.widthPercentage(invalidContext!, 0.5), throwsA(isA<TypeError>()));
      });
    });
  });
}
