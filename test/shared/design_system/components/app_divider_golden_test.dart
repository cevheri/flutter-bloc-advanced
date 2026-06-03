import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_divider.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 2,
    children: [
      GoldenTestScenario(
        name: 'plain',
        child: const SizedBox(width: 200, child: AppDivider()),
      ),
      GoldenTestScenario(
        name: 'with label',
        child: const SizedBox(width: 200, child: AppDivider(label: 'OR')),
      ),
    ],
  );

  goldenTest('AppDivider — light', fileName: 'app_divider_light', builder: grid);

  goldenTest(
    'AppDivider — dark',
    fileName: 'app_divider_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
