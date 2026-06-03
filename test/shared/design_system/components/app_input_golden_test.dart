import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_input.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 2,
    children: [
      // standard — empty
      GoldenTestScenario(
        name: 'standard empty',
        child: SizedBox(
          width: 280,
          child: FormBuilder(
            child: AppInput(name: 'std_empty', label: 'Username', variant: AppInputVariant.standard),
          ),
        ),
      ),
      // standard — with initial value
      GoldenTestScenario(
        name: 'standard with text',
        child: SizedBox(
          width: 280,
          child: FormBuilder(
            child: AppInput(
              name: 'std_text',
              label: 'Username',
              initialValue: 'john.doe',
              variant: AppInputVariant.standard,
            ),
          ),
        ),
      ),
      // standard — with error (via validator result shown after autovalidate)
      GoldenTestScenario(
        name: 'standard with error',
        child: SizedBox(
          width: 280,
          child: FormBuilder(
            autovalidateMode: AutovalidateMode.always,
            child: AppInput(
              name: 'std_error',
              label: 'Email',
              initialValue: 'not-an-email',
              variant: AppInputVariant.standard,
              validator: (_) => 'Invalid email address',
            ),
          ),
        ),
      ),
      // search — empty
      GoldenTestScenario(
        name: 'search empty',
        child: SizedBox(
          width: 280,
          child: AppInput(name: 'srch_empty', hint: 'Search…', variant: AppInputVariant.search),
        ),
      ),
      // search — with text (clear button visible)
      GoldenTestScenario(
        name: 'search with text',
        child: SizedBox(
          width: 280,
          child: AppInput(name: 'srch_text', hint: 'Search…', initialValue: 'flutter', variant: AppInputVariant.search),
        ),
      ),
    ],
  );

  goldenTest('AppInput — light', fileName: 'app_input_light', builder: grid);

  goldenTest(
    'AppInput — dark',
    fileName: 'app_input_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
