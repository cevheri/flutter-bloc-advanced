import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  // A representative grid of button variants + a loading state. The `icon`
  // variant needs an icon; all others use a text label.
  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 3,
    children: [
      for (final v in AppButtonVariant.values)
        GoldenTestScenario(
          name: v.name,
          child: v == AppButtonVariant.icon
              ? AppButton(variant: v, icon: Icons.add, onPressed: () {})
              : AppButton(label: 'Button', variant: v, onPressed: () {}),
        ),
      GoldenTestScenario(
        name: 'loading',
        child: const AppButton(label: 'Button', isLoading: true),
      ),
    ],
  );

  // pumpOnce is used instead of the default pumpAndSettle to avoid a timeout
  // caused by the CircularProgressIndicator in the 'loading' scenario, which
  // never settles because it animates indefinitely.
  goldenTest('AppButton — light', fileName: 'app_button_light', pumpBeforeTest: pumpOnce, builder: grid);

  goldenTest(
    'AppButton — dark',
    fileName: 'app_button_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
