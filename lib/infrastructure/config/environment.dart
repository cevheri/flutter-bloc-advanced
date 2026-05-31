import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';

/// This file is used to set the environment
enum Environment { dev, prod, test }

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.certificatePins,
    required this.idleTimeout,
  });

  const AppConfig.dev()
    : environment = Environment.dev,
      apiBaseUrl = null,
      certificatePins = const <String>[],
      idleTimeout = null;

  const AppConfig.test()
    : environment = Environment.test,
      apiBaseUrl = null,
      certificatePins = const <String>[],
      idleTimeout = null;

  const AppConfig.prod()
    : environment = Environment.prod,
      apiBaseUrl = TemplateConfig.prodApiUrl,
      certificatePins = const <String>[],
      idleTimeout = const Duration(minutes: 15);

  factory AppConfig.fromEnvironment(Environment environment) {
    return switch (environment) {
      Environment.dev => const AppConfig.dev(),
      Environment.prod => const AppConfig.prod(),
      Environment.test => const AppConfig.test(),
    };
  }

  final Environment environment;
  final String? apiBaseUrl;
  final List<String> certificatePins;
  final Duration? idleTimeout;

  bool get isProduction => environment == Environment.prod;
  bool get isDevelopment => environment == Environment.dev;
  bool get isTest => environment == Environment.test;

  /// Production-only DSN passed via `--dart-define=SENTRY_DSN=...`.
  /// Returns null in non-prod, or when the define is absent / empty
  /// so the bootstrap falls back to [LogAnalyticsService] without
  /// touching the Sentry SDK.
  ///
  /// **Never** commit a DSN to source. The repo is a public template;
  /// a checked-in DSN means anyone running the fork ships events into
  /// the original project's Sentry quota.
  String? get sentryDsn {
    if (!isProduction) return null;
    const dsn = String.fromEnvironment('SENTRY_DSN');
    return dsn.isEmpty ? null : dsn;
  }
}
