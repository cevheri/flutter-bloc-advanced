@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/command_palette/command_palette_widget.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openPalette(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    AuthMode authMode = const JwtAuthMode(),
  }) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthMode>.value(
        value: authMode,
        child: MaterialApp(
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
              builder: (context) =>
                  TextButton(onPressed: () => CommandPalette.show(context), child: const Text('open')),
            ),
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

    // String.toLowerCase turns I into i and İ into i with a combining dot, so a search in capitals missed the
    // Turkish commands.
    testWidgets('finds the commands from a search in Turkish capitals', (tester) async {
      await openPalette(tester, locale: const Locale('tr'));

      await tester.enterText(find.byType(TextField), 'KULLANICI');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Kullanıcılar'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ŞİFRE');
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Şifre Değiştir'), findsOneWidget);
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

    // Guards that the Turkish folding stays out of English, where I is the capital of i.
    testWidgets('finds the commands from a search in English capitals', (tester) async {
      await openPalette(tester);

      await tester.enterText(find.byType(TextField), 'SETTINGS');
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Settings'), findsOneWidget);
    });
  });

  group('CommandPalette in oidc mode', () {
    for (final (build, authMode) in <(String, AuthMode)>[
      ('an oidc build', OidcAuthMode(OidcSettings(issuer: Uri.parse('https://id.example.com'), clientId: 'app'))),
      ('a misconfigured oidc build', const OidcMisconfiguredAuthMode('OIDC_ISSUER is required in oidc mode')),
    ]) {
      // The identity provider owns the password, so the app has no page to change it.
      testWidgets('in $build, offers no change-password command', (tester) async {
        await openPalette(tester, authMode: authMode);

        expect(find.widgetWithText(ListTile, 'Settings'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Change Password'), findsNothing);

        await tester.enterText(find.byType(TextField), 'password');
        await tester.pumpAndSettle();

        expect(find.byType(ListTile), findsNothing);
      });
    }
  });
}
