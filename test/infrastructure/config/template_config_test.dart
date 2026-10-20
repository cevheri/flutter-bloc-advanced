import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Made-up keys: replacing the template's real placeholders across a project leaves these tests as they are.
  group('TemplateConfig.isUnfilled', () {
    test('a placeholder is not filled in', () {
      for (final value in ['__KEY__', '__SOME_URL__', '__A1_B2__']) {
        expect(TemplateConfig.isUnfilled(value), isTrue, reason: value);
      }
    });

    test('an empty value is not filled in', () {
      expect(TemplateConfig.isUnfilled(''), isTrue);
    });

    test('a URL is filled in', () {
      for (final value in ['https://github.com/acme/dashboard', 'https://docs.acme.example/__init__/']) {
        expect(TemplateConfig.isUnfilled(value), isFalse, reason: value);
      }
    });

    // The deploy check (scripts/check_web_placeholders.sh) matches the same pattern, so a value that passes the check
    // is shown by the app.
    test('only an upper-case key between double underscores is a placeholder', () {
      for (final value in ['__key__', '_KEY_', '__1KEY__', '____', ' __KEY__', '__KEY__ ']) {
        expect(TemplateConfig.isUnfilled(value), isFalse, reason: "'$value'");
      }
    });
  });
}
