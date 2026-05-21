import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';

/// This file is used to set the environment
enum Environment { dev, prod, test }

/// This class is used to store all environment variables
///
/// It is used in the main_local.dart file to set the environment
class ProfileConstants {
  static Map<String, dynamic>? _config;

  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.dev:
        _config = _Config.devConstants;
        break;
      case Environment.test:
        _config = _Config.testConstants;
        break;
      case Environment.prod:
        _config = _Config.prodConstants;
        break;
    }
  }

  static bool get isProduction {
    return _config == _Config.prodConstants;
  }

  static bool get isDevelopment {
    return _config == _Config.devConstants;
  }

  static bool get isTest {
    return _config == _Config.testConstants;
  }

  static dynamic get api {
    return _config![_Config.api];
  }

  /// Production-only DSN passed via `--dart-define=SENTRY_DSN=...`.
  /// Returns null in non-prod, or when the define is absent / empty
  /// so the bootstrap falls back to [LogAnalyticsService] without
  /// touching the Sentry SDK.
  ///
  /// **Never** commit a DSN to source. The repo is a public template;
  /// a checked-in DSN means anyone running the fork ships events into
  /// the original project's Sentry quota.
  static String? get sentryDsn {
    if (!isProduction) return null;
    const dsn = String.fromEnvironment('SENTRY_DSN');
    return dsn.isEmpty ? null : dsn;
  }
}

class _Config {
  static const api = "API";

  static Map<String, dynamic> devConstants = {api: "mock"};

  static Map<String, dynamic> testConstants = {api: "mock"};

  static Map<String, dynamic> prodConstants = {api: TemplateConfig.prodApiUrl};
}
