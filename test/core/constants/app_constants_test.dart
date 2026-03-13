import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Constants values", () {
    test('appKey should match TemplateConfig', () {
      expect(AppConstants.appKey, TemplateConfig.appKey);
    });
    test('appName should match TemplateConfig', () {
      expect(AppConstants.appName, TemplateConfig.appName);
    });
    test('appVersion should be 1.0.0', () {
      expect(AppConstants.appVersion, '1.0.0');
    });
    test('appDescription should match TemplateConfig', () {
      expect(AppConstants.appDescription, TemplateConfig.appDescription);
    });
    test('appAuthor should match TemplateConfig', () {
      expect(AppConstants.appAuthor, TemplateConfig.authorName);
    });
    test('appAuthorEmail should match TemplateConfig', () {
      expect(AppConstants.appAuthorEmail, TemplateConfig.authorEmail);
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
