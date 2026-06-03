import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_status_badge.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 3,
    children: [
      GoldenTestScenario(
        name: 'active',
        child: const AppStatusBadge(label: 'Active', color: Colors.green),
      ),
      GoldenTestScenario(
        name: 'pending',
        child: const AppStatusBadge(label: 'Pending', color: Colors.amber),
      ),
      GoldenTestScenario(
        name: 'error',
        child: const AppStatusBadge(label: 'Error', color: Colors.red),
      ),
    ],
  );

  goldenTest('AppStatusBadge — light', fileName: 'app_status_badge_light', builder: grid);

  goldenTest(
    'AppStatusBadge — dark',
    fileName: 'app_status_badge_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
