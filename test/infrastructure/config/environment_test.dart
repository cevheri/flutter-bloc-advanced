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
      expect(config.isTest, true);
      expect(config.apiBaseUrl, isNull);
    });
    test('prod config sets production environment', () {
      const config = AppConfig.prod();
      expect(config.isProduction, true);
      expect(config.apiBaseUrl, TemplateConfig.prodApiUrl);
      expect(config.idleTimeout, const Duration(minutes: 15));
      expect(config.certificatePins, isEmpty);
    });
    test('fromEnvironment maps each enum value', () {
      expect(AppConfig.fromEnvironment(Environment.dev).isDevelopment, true);
      expect(AppConfig.fromEnvironment(Environment.test).isTest, true);
      expect(AppConfig.fromEnvironment(Environment.prod).isProduction, true);
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
