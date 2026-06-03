import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/user_form_fields.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

// ---------------------------------------------------------------------------
// UserFormFields uses S.of(context) → we need the S.delegate in scope.
// ---------------------------------------------------------------------------

Future<void> _pumpWithL10n(WidgetTester tester, Widget widget) => tester.pumpWidget(
  Localizations(
    locale: const Locale('en'),
    delegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    child: widget,
  ),
);

// ---------------------------------------------------------------------------
// Scenarios
// ---------------------------------------------------------------------------

final _formKey = GlobalKey<FormBuilderState>();

GoldenTestGroup _grid() => GoldenTestGroup(
  columns: 1,
  children: [
    GoldenTestScenario(
      name: 'all-fields',
      child: SizedBox(
        width: 400,
        child: Builder(
          builder: (context) => FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserFormFields.usernameField(context, 'johndoe'),
                const SizedBox(height: 8),
                UserFormFields.firstNameField(context, 'John'),
                const SizedBox(height: 8),
                UserFormFields.lastNameField(context, 'Doe'),
                const SizedBox(height: 8),
                UserFormFields.emailField(context, 'john@example.com'),
              ],
            ),
          ),
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

  goldenTest('UserFormFields — light', fileName: 'user_form_fields_light', pumpWidget: _pumpWithL10n, builder: _grid);

  goldenTest(
    'UserFormFields — dark',
    fileName: 'user_form_fields_dark',
    pumpWidget: _pumpWithL10n,
    builder: () => Theme(data: AppTheme.dark(), child: _grid()),
  );
}
