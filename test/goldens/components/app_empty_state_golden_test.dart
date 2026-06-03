import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_empty_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 2,
    children: [
      // minimal — icon + title only
      GoldenTestScenario(
        name: 'minimal',
        child: SizedBox(width: 320, child: AppEmptyState(title: 'No items found')),
      ),
      // full — icon + title + description + action button
      GoldenTestScenario(
        name: 'with description and action',
        child: SizedBox(
          width: 320,
          child: AppEmptyState(
            icon: Icons.folder_open,
            title: 'No documents yet',
            description: 'Create your first document to get started.',
            actionLabel: 'Create Document',
            onAction: () {},
          ),
        ),
      ),
      // custom icon, no action
      GoldenTestScenario(
        name: 'custom icon no action',
        child: SizedBox(
          width: 320,
          child: AppEmptyState(
            icon: Icons.search_off,
            title: 'No results',
            description: 'Try adjusting your search or filters.',
          ),
        ),
      ),
    ],
  );

  goldenTest('AppEmptyState — light', fileName: 'app_empty_state_light', builder: grid);

  goldenTest(
    'AppEmptyState — dark',
    fileName: 'app_empty_state_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
