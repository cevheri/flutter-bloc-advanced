import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_form.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  // A single composed form: AppFormCard wrapping an AppFormSection with two
  // AppFormFields (plain TextFields — no FormBuilder dependency) and an
  // AppFormActions footer.
  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 1,
    children: [
      GoldenTestScenario(
        name: 'profile form',
        child: SizedBox(
          width: 360,
          child: AppFormCard(
            header: const Text('Edit Profile'),
            footer: AppFormActions(
              secondaryAction: OutlinedButton(onPressed: null, child: const Text('Cancel')),
              primaryAction: FilledButton(onPressed: null, child: const Text('Save')),
            ),
            child: AppFormSection(
              title: 'Profile',
              children: [
                AppFormField(
                  label: 'Name',
                  child: const TextField(decoration: InputDecoration(hintText: 'Jane Doe')),
                ),
                const SizedBox(height: 16),
                AppFormField(
                  label: 'Email',
                  description: 'We never share it',
                  child: const TextField(decoration: InputDecoration(hintText: 'jane@example.com')),
                ),
                const SizedBox(height: 16),
                AppFormField(
                  label: 'Bio',
                  errorText: 'Bio is required',
                  child: const TextField(decoration: InputDecoration(hintText: 'Tell us about yourself')),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  goldenTest('AppForm — light', fileName: 'app_form_light', builder: grid);

  goldenTest(
    'AppForm — dark',
    fileName: 'app_form_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
