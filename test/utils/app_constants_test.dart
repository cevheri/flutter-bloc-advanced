import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Constants values", () {
    test('appKey should be flutter_bloc_advanced', () {
      expect(AppConstants.appKey, 'flutter_bloc_advanced');
    });
    test('appName should be FlutterTemplate', () {
      expect(AppConstants.appName, 'FlutterTemplate');
    });
    test('appVersion should be 1.0.0', () {
      expect(AppConstants.appVersion, AppConstants.appVersion);
    });
    test('appDescription should be', () {
      expect(AppConstants.appDescription, 'Flutter Template with BLOC and Clean Architecture');
    });
    test('appAuthor should be sample.tech', () {
      expect(AppConstants.appAuthor, 'sample.tech');
    });
    test('appAuthorEmail should be', () {
      expect(AppConstants.appAuthorEmail, 'info@sample.tech');
    });
  });

  group('UpperCaseTextFormatter', () {
    final formatter = UpperCaseTextFormatter();

    test('formats lowercase text to uppercase', () {
      const oldValue = TextEditingValue(text: 'hello');
      const newValue = TextEditingValue(text: 'world');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'WORLD');
    });

    test('keeps uppercase text as uppercase', () {
      const oldValue = TextEditingValue(text: 'HELLO');
      const newValue = TextEditingValue(text: 'WORLD');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'WORLD');
    });

    test('formats mixed case text to uppercase', () {
      const oldValue = TextEditingValue(text: 'HeLLo');
      const newValue = TextEditingValue(text: 'WoRLd');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'WORLD');
    });

    test('keeps selection position after formatting', () {
      const oldValue = TextEditingValue(text: 'hello', selection: TextSelection.collapsed(offset: 5));
      const newValue = TextEditingValue(text: 'world', selection: TextSelection.collapsed(offset: 5));
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.selection, const TextSelection.collapsed(offset: 5));
    });

    test('handles empty text', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: '');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });
  });
}
