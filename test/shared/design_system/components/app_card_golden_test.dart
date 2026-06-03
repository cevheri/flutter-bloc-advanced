import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_card.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 3,
    children: [
      for (final v in AppCardVariant.values)
        GoldenTestScenario(
          name: v.name,
          child: SizedBox(
            width: 200,
            child: AppCard(
              variant: v,
              child: const Padding(padding: EdgeInsets.all(16), child: Text('Card body')),
            ),
          ),
        ),
    ],
  );

  goldenTest('AppCard — light', fileName: 'app_card_light', builder: grid);

  goldenTest(
    'AppCard — dark',
    fileName: 'app_card_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
