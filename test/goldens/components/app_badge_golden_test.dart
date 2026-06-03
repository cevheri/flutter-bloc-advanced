import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_badge.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 4,
    children: [
      for (final v in AppBadgeVariant.values)
        GoldenTestScenario(
          name: v.name,
          child: AppBadge(label: v.name, variant: v),
        ),
      GoldenTestScenario(
        name: 'with icon',
        child: const AppBadge(label: 'Done', variant: AppBadgeVariant.success, icon: Icons.check),
      ),
    ],
  );

  goldenTest('AppBadge — light', fileName: 'app_badge_light', builder: grid);

  goldenTest(
    'AppBadge — dark',
    fileName: 'app_badge_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
