import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/theme_selection_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

// ThemeSelectionDialog uses BlocBuilder<ThemeBloc, ThemeState>, so a ThemeBloc
// must be available in the widget tree. We inject it via BlocProvider.
Widget _withBloc(Widget child) => BlocProvider(create: (_) => ThemeBloc(), child: child);

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 1,
    children: [
      GoldenTestScenario(
        name: 'default',
        // ThemeSelectionDialog renders a Dialog with internal maxWidth:400,
        // maxHeight:600 constraints. We give the host enough room so it does
        // not further constrain the dialog's internal layout.
        child: Center(child: SizedBox(width: 500, height: 700, child: _withBloc(const ThemeSelectionDialog()))),
      ),
    ],
  );

  goldenTest('ThemeSelectionDialog — light', fileName: 'theme_selection_dialog_light', builder: grid);

  goldenTest(
    'ThemeSelectionDialog — dark',
    fileName: 'theme_selection_dialog_dark',
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
