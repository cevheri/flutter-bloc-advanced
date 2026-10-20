@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/widgets/theme_selection_dialog.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ThemeBloc(),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(onPressed: () => ThemeSelectionDialog.show(context), child: const Text('Open')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('ThemeSelectionDialog', () {
    testWidgets('puts Cancel and Apply at the end of the dialog when they fit on one line', (tester) async {
      await openDialog(tester, const Size(412, 915));

      final close = tester.getRect(find.widgetWithIcon(IconButton, Icons.close));
      final cancel = tester.getRect(find.widgetWithText(TextButton, 'Cancel'));
      final apply = tester.getRect(find.widgetWithText(FilledButton, 'Apply'));
      expect(apply.top, cancel.top);
      expect(apply.right, close.right);
    });

    for (final textScale in [1.0, 1.3]) {
      testWidgets('fits a 320 px wide phone at text scale $textScale', (tester) async {
        await openDialog(tester, const Size(320, 568), textScale: textScale);

        expect(tester.takeException(), isNull);
        expect(find.text('Choose Theme'), findsOneWidget);
        expect(find.text('Apply'), findsOneWidget);
      });
    }
  });
  group('ThemeSelectionDialog - language', () {
    testWidgets('shows the palette descriptions without a dash in English', (tester) async {
      await openDialog(tester, const Size(412, 915));

      expect(find.text('Neutral zinc, clean and minimal'), findsOneWidget);
    });

    for (final textScale in [1.0, 1.3]) {
      testWidgets('shows its texts in Turkish on a 320 px wide phone at text scale $textScale', (tester) async {
        await openDialog(tester, const Size(320, 568), textScale: textScale, locale: const Locale('tr'));

        expect(tester.takeException(), isNull);
        for (final text in [
          'Tema Seçin',
          'Tercih ettiğiniz tema stilini seçin',
          'Klasik',
          'Nötr çinko, sade ve minimal',
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        expect(find.widgetWithText(TextButton, 'İptal'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Uygula'), findsOneWidget);
      });
    }
  });
}
