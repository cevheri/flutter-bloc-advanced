import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/semantic_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SemanticColors light', () {
    const colors = SemanticColors.light;

    test('success is Green 600', () {
      expect(colors.success, const Color(0xFF16A34A));
    });

    test('onSuccess is white', () {
      expect(colors.onSuccess, const Color(0xFFFFFFFF));
    });

    test('successContainer is Green 100', () {
      expect(colors.successContainer, const Color(0xFFDCFCE7));
    });

    test('onSuccessContainer is Green 900', () {
      expect(colors.onSuccessContainer, const Color(0xFF14532D));
    });

    test('warning is Yellow 500', () {
      expect(colors.warning, const Color(0xFFEAB308));
    });

    test('onWarning is black', () {
      expect(colors.onWarning, const Color(0xFF000000));
    });

    test('warningContainer is Yellow 100', () {
      expect(colors.warningContainer, const Color(0xFFFEF9C3));
    });

    test('onWarningContainer is Yellow 900', () {
      expect(colors.onWarningContainer, const Color(0xFF713F12));
    });

    test('info is Blue 600', () {
      expect(colors.info, const Color(0xFF2563EB));
    });

    test('onInfo is white', () {
      expect(colors.onInfo, const Color(0xFFFFFFFF));
    });

    test('infoContainer is Blue 100', () {
      expect(colors.infoContainer, const Color(0xFFDBEAFE));
    });

    test('onInfoContainer is Blue 900', () {
      expect(colors.onInfoContainer, const Color(0xFF1E3A8A));
    });
  });

  group('SemanticColors dark', () {
    const colors = SemanticColors.dark;

    test('success is Green 400', () {
      expect(colors.success, const Color(0xFF4ADE80));
    });

    test('onSuccess is Green 950', () {
      expect(colors.onSuccess, const Color(0xFF052E16));
    });

    test('successContainer is Green 800', () {
      expect(colors.successContainer, const Color(0xFF166534));
    });

    test('onSuccessContainer is Green 200', () {
      expect(colors.onSuccessContainer, const Color(0xFFBBF7D0));
    });

    test('warning is Yellow 400', () {
      expect(colors.warning, const Color(0xFFFACC15));
    });

    test('onWarning is black', () {
      expect(colors.onWarning, const Color(0xFF000000));
    });

    test('warningContainer is Yellow 800', () {
      expect(colors.warningContainer, const Color(0xFF854D0E));
    });

    test('onWarningContainer is Yellow 200', () {
      expect(colors.onWarningContainer, const Color(0xFFFEF08A));
    });

    test('info is Blue 400', () {
      expect(colors.info, const Color(0xFF60A5FA));
    });

    test('onInfo is Blue 950', () {
      expect(colors.onInfo, const Color(0xFF172554));
    });

    test('infoContainer is Blue 800', () {
      expect(colors.infoContainer, const Color(0xFF1E40AF));
    });

    test('onInfoContainer is Blue 200', () {
      expect(colors.onInfoContainer, const Color(0xFFBFDBFE));
    });
  });

  group('SemanticColors light and dark differ', () {
    test('success colors differ between light and dark', () {
      expect(SemanticColors.light.success, isNot(equals(SemanticColors.dark.success)));
    });

    test('warning colors differ between light and dark', () {
      expect(SemanticColors.light.warning, isNot(equals(SemanticColors.dark.warning)));
    });

    test('info colors differ between light and dark', () {
      expect(SemanticColors.light.info, isNot(equals(SemanticColors.dark.info)));
    });
  });

  group('SemanticColors copyWith', () {
    test('returns new instance with updated success', () {
      const original = SemanticColors.light;
      final updated = original.copyWith(success: const Color(0xFF000000));
      expect(updated.success, const Color(0xFF000000));
      expect(updated.onSuccess, original.onSuccess);
      expect(updated.warning, original.warning);
      expect(updated.info, original.info);
    });

    test('returns new instance with updated warning', () {
      const original = SemanticColors.light;
      final updated = original.copyWith(warning: const Color(0xFFFF0000));
      expect(updated.warning, const Color(0xFFFF0000));
      expect(updated.success, original.success);
    });

    test('returns new instance with updated info', () {
      const original = SemanticColors.light;
      final updated = original.copyWith(info: const Color(0xFF00FF00));
      expect(updated.info, const Color(0xFF00FF00));
      expect(updated.success, original.success);
    });

    test('preserves all values when no arguments provided', () {
      const original = SemanticColors.light;
      final copy = original.copyWith();
      expect(copy.success, original.success);
      expect(copy.onSuccess, original.onSuccess);
      expect(copy.successContainer, original.successContainer);
      expect(copy.onSuccessContainer, original.onSuccessContainer);
      expect(copy.warning, original.warning);
      expect(copy.onWarning, original.onWarning);
      expect(copy.warningContainer, original.warningContainer);
      expect(copy.onWarningContainer, original.onWarningContainer);
      expect(copy.info, original.info);
      expect(copy.onInfo, original.onInfo);
      expect(copy.infoContainer, original.infoContainer);
      expect(copy.onInfoContainer, original.onInfoContainer);
    });

    test('updates all container colors', () {
      const original = SemanticColors.light;
      final updated = original.copyWith(
        successContainer: const Color(0xFF111111),
        onSuccessContainer: const Color(0xFF222222),
        warningContainer: const Color(0xFF333333),
        onWarningContainer: const Color(0xFF444444),
        infoContainer: const Color(0xFF555555),
        onInfoContainer: const Color(0xFF666666),
      );
      expect(updated.successContainer, const Color(0xFF111111));
      expect(updated.onSuccessContainer, const Color(0xFF222222));
      expect(updated.warningContainer, const Color(0xFF333333));
      expect(updated.onWarningContainer, const Color(0xFF444444));
      expect(updated.infoContainer, const Color(0xFF555555));
      expect(updated.onInfoContainer, const Color(0xFF666666));
    });
  });

  group('SemanticColors lerp', () {
    test('lerp at t=0 returns start colors', () {
      const start = SemanticColors.light;
      const end = SemanticColors.dark;
      final result = start.lerp(end, 0.0);
      expect(result.success, start.success);
      expect(result.warning, start.warning);
      expect(result.info, start.info);
    });

    test('lerp at t=1 returns end colors', () {
      const start = SemanticColors.light;
      const end = SemanticColors.dark;
      final result = start.lerp(end, 1.0);
      expect(result.success, end.success);
      expect(result.warning, end.warning);
      expect(result.info, end.info);
    });

    test('lerp at t=0.5 returns intermediate colors', () {
      const start = SemanticColors.light;
      const end = SemanticColors.dark;
      final result = start.lerp(end, 0.5);
      expect(result.success, Color.lerp(start.success, end.success, 0.5));
      expect(result.warning, Color.lerp(start.warning, end.warning, 0.5));
      expect(result.info, Color.lerp(start.info, end.info, 0.5));
    });

    test('lerp with non-SemanticColors returns this', () {
      const start = SemanticColors.light;
      final result = start.lerp(null, 0.5);
      expect(result.success, start.success);
      expect(result.warning, start.warning);
      expect(result.info, start.info);
    });
  });

  group('SemanticColorsExtension', () {
    testWidgets('provides semantic colors from theme', (tester) async {
      late SemanticColors capturedColors;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [SemanticColors.light]),
          home: Builder(
            builder: (context) {
              capturedColors = context.semanticColors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedColors.success, SemanticColors.light.success);
      expect(capturedColors.warning, SemanticColors.light.warning);
      expect(capturedColors.info, SemanticColors.light.info);
    });

    testWidgets('provides dark semantic colors from dark theme', (tester) async {
      late SemanticColors capturedColors;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: [SemanticColors.dark]),
          home: Builder(
            builder: (context) {
              capturedColors = context.semanticColors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedColors.success, SemanticColors.dark.success);
      expect(capturedColors.warning, SemanticColors.dark.warning);
      expect(capturedColors.info, SemanticColors.dark.info);
    });
  });
}
