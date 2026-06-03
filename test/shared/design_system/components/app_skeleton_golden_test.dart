import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_skeleton.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  // Each shape gets a bounded SizedBox so the shimmer has known dimensions.
  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 3,
    children: [
      GoldenTestScenario(
        name: AppSkeletonShape.text.name,
        child: const SizedBox(width: 120, height: 16, child: AppSkeleton.text(width: 120, height: 16)),
      ),
      GoldenTestScenario(
        name: AppSkeletonShape.circle.name,
        child: const SizedBox(width: 48, height: 48, child: AppSkeleton.circle(diameter: 48)),
      ),
      GoldenTestScenario(
        name: AppSkeletonShape.rectangle.name,
        child: const SizedBox(
          width: 120,
          height: 40,
          child: AppSkeleton(shape: AppSkeletonShape.rectangle, width: 120, height: 40),
        ),
      ),
      GoldenTestScenario(
        name: AppSkeletonShape.card.name,
        child: const SizedBox(width: 160, height: 100, child: AppSkeleton.card(width: 160, height: 100)),
      ),
      GoldenTestScenario(
        name: AppSkeletonShape.listTile.name,
        // listTile uses Expanded internally — wrap in a bounded width.
        child: SizedBox(width: 240, height: 56, child: AppSkeleton.listTile()),
      ),
    ],
  );

  // pumpOnce is required: the Shimmer animation never settles, so the default
  // pumpAndSettle would time out. A single pump captures the initial frame.
  goldenTest('AppSkeleton — light', fileName: 'app_skeleton_light', pumpBeforeTest: pumpOnce, builder: grid);

  goldenTest(
    'AppSkeleton — dark',
    fileName: 'app_skeleton_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
