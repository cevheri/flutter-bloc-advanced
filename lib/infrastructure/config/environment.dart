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

  /// Pinned certificate SHA-256 hashes (base64, e.g. produced by
  /// `openssl dgst -sha256 -binary | openssl enc -base64`).
  /// Empty list = pinning disabled (default).
  ///
  /// See `lib/infrastructure/http/certificate_pinning_adapter.dart` for
  /// the live validation behaviour, and the README "Certificate Pinning"
  /// section for the extraction one-liner + key-rotation procedure.
  static List<String> get certificatePins {
    final raw = _config?[_Config.certificatePins];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }
}

class _Config {
  static const api = "API";
  static const certificatePins = "CERTIFICATE_PINS";

  static Map<String, dynamic> devConstants = {api: "mock", certificatePins: <String>[]};

  static Map<String, dynamic> testConstants = {api: "mock", certificatePins: <String>[]};

  /// Production default: pinning ships disabled (empty list). Add
  /// base64 SHA-256 pins extracted from your live backend's certificate
  /// to enable. Backup pin support is automatic — list two and rotate
  /// per the README procedure.
  static Map<String, dynamic> prodConstants = {api: TemplateConfig.prodApiUrl, certificatePins: <String>[]};
}
