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
  static const certificatePins = "CERTIFICATE_PINS";
  static const idleTimeoutSeconds = "IDLE_TIMEOUT_SECONDS";

  /// Dev / test default: pinning disabled (empty list) and idle timeout off.
  /// Mocked sessions and rapid hot-reload flows would be hostile if the
  /// observer logged the user out mid-edit.
  static Map<String, dynamic> devConstants = {api: "mock", certificatePins: <String>[], idleTimeoutSeconds: null};

  static Map<String, dynamic> testConstants = {api: "mock", certificatePins: <String>[], idleTimeoutSeconds: null};

  /// Production defaults: pinning ships disabled (empty list) — add base64
  /// SHA-256 pins extracted from your live backend's certificate to enable
  /// (backup pin support is automatic; list two and rotate per the README).
  /// Idle timeout defaults to 15 minutes (industry baseline for non-financial
  /// apps; financial-grade forks should lower to 5 minutes).
  static Map<String, dynamic> prodConstants = {
    api: TemplateConfig.prodApiUrl,
    certificatePins: <String>[],
    idleTimeoutSeconds: 15 * 60,
  };
}
