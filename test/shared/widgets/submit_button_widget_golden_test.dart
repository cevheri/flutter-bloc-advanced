import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/submit_button_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

// ---------------------------------------------------------------------------
// Scenarios
// ---------------------------------------------------------------------------

GoldenTestGroup _grid() => GoldenTestGroup(
  columns: 1,
  children: [
    GoldenTestScenario(
      name: 'idle',
      child: SizedBox(
        width: 200,
        child: ResponsiveSubmitButton(buttonText: 'Save', onPressed: () {}, isLoading: false, isWebPlatform: false),
      ),
    ),
    GoldenTestScenario(
      name: 'loading',
      child: SizedBox(
        width: 200,
        child: ResponsiveSubmitButton(buttonText: 'Save', onPressed: () {}, isLoading: true, isWebPlatform: false),
      ),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Golden tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  goldenTest(
    'ResponsiveSubmitButton — light',
    fileName: 'submit_button_widget_light',
    pumpBeforeTest: pumpOnce,
    builder: _grid,
  );

  goldenTest(
    'ResponsiveSubmitButton — dark',
    fileName: 'submit_button_widget_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => Theme(data: AppTheme.dark(), child: _grid()),
  );
}
