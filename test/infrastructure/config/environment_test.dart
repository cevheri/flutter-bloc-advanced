import 'package:flutter_bloc_advance/core/security/allowed_paths.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('dev config sets development environment', () {
      const config = AppConfig.dev();
      expect(config.isDevelopment, true);
      expect(config.apiBaseUrl, isNull);
    });

    test('test config sets test environment', () {
      const config = AppConfig.test();
      expect(config.isDevelopment, false);
      expect(config.isProduction, false);
      expect(config.apiBaseUrl, isNull);
    });

    test('prod config sets production environment', () {
      const config = AppConfig.prod();
      expect(config.isProduction, true);
      expect(config.apiBaseUrl, TemplateConfig.prodApiUrl);
    });
  });
  test("allowed paths", () {
    expect(allowedPaths, [
      '/authenticate',
      '/register',
      '/logout',
      '/account/reset-password/init',
      '/forgot-password',
      '/login-otp',
      '/login-otp-verify',
      '/authenticate/send-otp',
      '/authenticate/verify-otp',
      '/api/token/refresh',
    ]);
  });
}
