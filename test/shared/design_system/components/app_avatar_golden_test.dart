import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_avatar.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart' show AppComponentSize;
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 4,
    children: [
      for (final status in AppAvatarStatus.values)
        GoldenTestScenario(
          name: status.name,
          child: AppAvatar(initials: 'AB', status: status),
        ),
      GoldenTestScenario(
        name: 'sm',
        child: const AppAvatar(initials: 'SM', size: AppComponentSize.sm),
      ),
      GoldenTestScenario(
        name: 'md',
        child: const AppAvatar(initials: 'MD', size: AppComponentSize.md),
      ),
      GoldenTestScenario(
        name: 'lg',
        child: const AppAvatar(initials: 'LG', size: AppComponentSize.lg),
      ),
    ],
  );

  goldenTest('AppAvatar — light', fileName: 'app_avatar_light', builder: grid);

  goldenTest(
    'AppAvatar — dark',
    fileName: 'app_avatar_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
