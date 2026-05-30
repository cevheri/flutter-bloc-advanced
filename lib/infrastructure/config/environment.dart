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

  /// Inactivity threshold for auto-logout. `null` disables the
  /// [IdleTimeoutObserver]; downstream forks override by editing
  /// [_Config.prodConstants] (or any env map). Stored as an int (seconds)
  /// in the map so the config can stay a plain `Map<String, dynamic>`.
  static Duration? get idleTimeout {
    final raw = _config?[_Config.idleTimeoutSeconds];
    if (raw is! int || raw <= 0) return null;
    return Duration(seconds: raw);
  }
}

class _Config {
  static const api = "API";
  static const idleTimeoutSeconds = "IDLE_TIMEOUT_SECONDS";

  /// Dev / test default: disabled. Mocked sessions and rapid hot-reload
  /// flows would be hostile if the observer logged the user out mid-edit.
  static Map<String, dynamic> devConstants = {api: "mock", idleTimeoutSeconds: null};

  static Map<String, dynamic> testConstants = {api: "mock", idleTimeoutSeconds: null};

  /// Production default: 15 minutes. Industry baseline for non-financial
  /// apps; financial-grade forks should lower to 5 minutes.
  static Map<String, dynamic> prodConstants = {api: TemplateConfig.prodApiUrl, idleTimeoutSeconds: 15 * 60};
}
