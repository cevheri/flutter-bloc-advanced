import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('S (Localization)', () {
    test('current throws assertion error when not initialized', () {
      expect(
        () => S.current,
        throwsA(isA<AssertionError>().having(
          (error) => error.message,
          'message',
          'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
        )),
      );
    });

    testWidgets('current returns instance after initialization', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(localizationsDelegates: const [S.delegate], supportedLocales: S.delegate.supportedLocales));
      await tester.pumpAndSettle();

      expect(S.current, isNotNull);
    });
  });

  group('Localization language code tests', () {
    test('should use languageCode when countryCode is empty', () async {
      const locale = Locale('tr', '');
      await S.load(locale);
      expect(Intl.defaultLocale, 'tr');
    });

    test('should use full locale string when countryCode exists', () async {
      const locale = Locale('tr', 'TR');
      await S.load(locale);
      expect(Intl.defaultLocale, 'tr_TR');
    });

    test('should handle null countryCode', () async {
      const locale = Locale('en');
      await S.load(locale);
      expect(Intl.defaultLocale, 'en');
    });
  });
}
