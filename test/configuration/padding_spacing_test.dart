import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/presentation/design_system/tokens/app_spacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSpacing', () {
    group('Constant values', () {
      test('Given spacing constants When accessed Then should return correct values', () {
        expect(AppSpacing.xs, 4.0);
        expect(AppSpacing.sm, 8.0);
        expect(AppSpacing.md, 12.0);
        expect(AppSpacing.lg, 16.0);
        expect(AppSpacing.xl, 24.0);
        expect(AppSpacing.xxl, 32.0);
        expect(AppSpacing.xxxl, 40.0);
        expect(AppSpacing.xxxxl, 48.0);
        expect(AppSpacing.xxxxxl, 64.0);
      });

      test('Given form width constants When accessed Then should return correct values', () {
        expect(AppSpacing.formMaxWidthSm, 200.0);
        expect(AppSpacing.formMaxWidthMd, 400.0);
        expect(AppSpacing.formMaxWidthLg, 600.0);
        expect(AppSpacing.formMaxWidthXl, 800.0);
      });
    });

    group('Percentage calculations', () {
      testWidgets('Given context When percentage methods called Then should calculate correct values', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final height = MediaQuery.of(context).size.height;
                final width = MediaQuery.of(context).size.width;

                expect(AppSpacing.heightPercent(context, 0.5), height * 0.5);
                expect(AppSpacing.widthPercent(context, 0.5), width * 0.5);
                return Container();
              },
            ),
          ),
        );
      });
    });
  });
}
