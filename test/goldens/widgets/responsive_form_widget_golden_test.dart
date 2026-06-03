import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/responsive_form_widget.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _formKey = GlobalKey<FormBuilderState>();

GoldenTestGroup _grid() => GoldenTestGroup(
  columns: 1,
  children: [
    GoldenTestScenario(
      name: 'default',
      child: SizedBox(
        width: 400,
        child: ResponsiveFormBuilder(
          formKey: _formKey,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'First name')),
            const TextField(decoration: InputDecoration(labelText: 'Last name')),
          ],
        ),
      ),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Golden tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  goldenTest('ResponsiveFormBuilder — light', fileName: 'responsive_form_widget_light', builder: _grid);

  goldenTest(
    'ResponsiveFormBuilder — dark',
    fileName: 'responsive_form_widget_dark',
    builder: () => Theme(data: AppTheme.dark(), child: _grid()),
  );
}
