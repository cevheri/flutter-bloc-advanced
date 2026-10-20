import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Constants values", () {
    test('appName should match TemplateConfig', () {
      expect(AppConstants.appName, TemplateConfig.appName);
    });
    test('appVersion should be 1.0.0', () {
      expect(AppConstants.appVersion, '1.0.0');
    });
  });
}
