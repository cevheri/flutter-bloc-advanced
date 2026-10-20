@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/shell/command_palette/command_palette_widget.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openPalette(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(onPressed: () => CommandPalette.show(context), child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('CommandPalette - Turkish', () {
    testWidgets('shows the hint and the commands in Turkish', (tester) async {
      await openPalette(tester, locale: const Locale('tr'));

      expect(find.widgetWithText(TextField, 'Bir komut yazın veya arayın...'), findsOneWidget);
      expect(find.text('Kullanıcılar'), findsOneWidget);
      expect(find.text('Kullanıcıları yönetin'), findsOneWidget);
      expect(find.text('Panel'), findsOneWidget);
    });

    testWidgets('searches the Turkish text the user reads', (tester) async {
      await openPalette(tester, locale: const Locale('tr'));

      await tester.enterText(find.byType(TextField), 'ayar');
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Ayarlar'), findsOneWidget);
    });

    testWidgets('says that nothing matched in Turkish', (tester) async {
      await openPalette(tester, locale: const Locale('tr'));

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
    });
  });

  group('CommandPalette - English', () {
    testWidgets('filters the commands by label', (tester) async {
      await openPalette(tester);

      await tester.enterText(find.byType(TextField), 'password');
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Change Password'), findsOneWidget);
    });
  });
}
