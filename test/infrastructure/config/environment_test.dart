import 'package:flutter_bloc_advance/core/security/allowed_paths.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileConstants', () {
    test('setEnvironment sets dev environment', () {
      ProfileConstants.setEnvironment(Environment.dev);
      expect(ProfileConstants.isDevelopment, true);
      expect(ProfileConstants.api, "mock");
    });

    test('setEnvironment sets test environment', () {
      ProfileConstants.setEnvironment(Environment.test);
      expect(ProfileConstants.isDevelopment, false);
      expect(ProfileConstants.isProduction, false);
      expect(ProfileConstants.api, "mock");
    });

    test('setEnvironment sets prod environment', () {
      ProfileConstants.setEnvironment(Environment.prod);
      expect(ProfileConstants.isProduction, true);
      expect(ProfileConstants.api, TemplateConfig.prodApiUrl);
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
