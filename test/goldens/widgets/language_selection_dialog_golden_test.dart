import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/language_selection_dialog.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

// LanguageSelectionDialog calls S.of(context), so we must inject S.delegate
// into the localization chain. The custom pumpWidget wraps the alchemist host
// widget inside a Localizations scope that carries S.delegate.
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

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 1,
    children: [
      GoldenTestScenario(
        name: 'default',
        child: Center(child: SizedBox(width: 320, child: const LanguageSelectionDialog())),
      ),
    ],
  );

  goldenTest(
    'LanguageSelectionDialog — light',
    fileName: 'language_selection_dialog_light',
    pumpWidget: _pumpWithL10n,
    builder: grid,
  );

  goldenTest(
    'LanguageSelectionDialog — dark',
    fileName: 'language_selection_dialog_dark',
    pumpWidget: _pumpWithL10n,
    builder: () => Theme(data: AppTheme.dark(), child: grid()),
  );
}
