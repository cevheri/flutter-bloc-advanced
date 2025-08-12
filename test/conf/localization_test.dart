import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/intl/messages_all.dart';
import 'package:flutter_bloc_advance/generated/intl/messages_en.dart' as message_en;
import 'package:flutter_bloc_advance/generated/intl/messages_tr.dart' as message_tr;

import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('S (Localization)', () {
    test('current throws assertion error when not initialized', () {
      expect(
        () => S.current,
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'message',
            'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
          ),
        ),
      );
    });

    testWidgets('current returns instance after initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(localizationsDelegates: const [S.delegate], supportedLocales: S.delegate.supportedLocales),
      );
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

  test('initializeJsonMapper', () {
    initializeJsonMapper();
  });
  test('initializeJsonMapper async', () {
    initializeJsonMapperAsync();
  });

  group('initializeMessages tests in messages_all.dart', () {
    test('should return false for unsupported locale', () async {
      // Test for an unsupported locale
      final result = await initializeMessages('fr');
      expect(result, false);
    });

    test('should return false when locale is null', () async {
      // Test when availableLocale becomes null
      final result = await initializeMessages('invalid_locale');
      expect(result, false);
    });

    test('should return true for supported locale', () async {
      // Test for a supported locale (en or tr)
      final result = await initializeMessages('en');
      expect(result, true);
    });
  });

  group("messages_en.dart localeName test", () {
    test("should return 'en' as localeName", () {
      final messages = message_en.MessageLookup();
      expect(messages.localeName, 'en');
    });
  });
  group("messages_tr.dart localeName test", () {
    test("should return 'tr' as localeName", () {
      final messages = message_tr.MessageLookup();
      expect(messages.localeName, 'tr');
    });
  });
}
