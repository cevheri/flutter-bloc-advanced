import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/confirmation_dialog_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  // ConfirmationDialog uses Theme.of(parentContext). We capture a live context
  // via Builder so parentContext resolves correctly inside the test host.
  Widget dialogForType(DialogType type) => Builder(
    builder: (ctx) => ConfirmationDialog(
      parentContext: ctx,
      title: switch (type) {
        DialogType.unsavedChanges => 'Warning',
        DialogType.delete => 'Warning',
        DialogType.logout => 'Logout',
      },
      message: switch (type) {
        DialogType.unsavedChanges => 'You have unsaved changes.',
        DialogType.delete => 'Are you sure you want to delete this record?',
        DialogType.logout => 'Are you sure you want to logout?',
      },
      confirmText: 'Yes',
      cancelText: 'No',
    ),
  );

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 3,
    children: [
      for (final type in DialogType.values)
        GoldenTestScenario(
          name: type.name,
          child: Center(child: SizedBox(width: 320, child: dialogForType(type))),
        ),
    ],
  );

  goldenTest('ConfirmationDialog — light', fileName: 'confirmation_dialog_light', builder: grid);

  goldenTest(
    'ConfirmationDialog — dark',
    fileName: 'confirmation_dialog_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
