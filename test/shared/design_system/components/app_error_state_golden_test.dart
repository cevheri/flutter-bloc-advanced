import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 2,
    children: [
      // title + retry button, with the other params at their defaults
      GoldenTestScenario(
        name: 'default',
        child: SizedBox(
          width: 320,
          child: AppErrorState(title: 'Something went wrong', retryLabel: 'Retry', onRetry: () {}),
        ),
      ),
      // full — custom title + description + custom icon + retry
      GoldenTestScenario(
        name: 'with description',
        child: SizedBox(
          width: 320,
          child: AppErrorState(
            icon: Icons.cloud_off,
            title: 'Connection failed',
            description: 'Check your internet connection and try again.',
            retryLabel: 'Try again',
            onRetry: () {},
          ),
        ),
      ),
      // no retry action — message only
      GoldenTestScenario(
        name: 'no retry',
        child: SizedBox(
          width: 320,
          child: AppErrorState(title: 'Access denied', description: 'You do not have permission to view this content.'),
        ),
      ),
    ],
  );

  goldenTest('AppErrorState — light', fileName: 'app_error_state_light', builder: grid);

  goldenTest(
    'AppErrorState — dark',
    fileName: 'app_error_state_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
