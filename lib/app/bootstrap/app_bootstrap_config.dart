import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';

class AppBootstrapConfig {
  const AppBootstrapConfig({
    required this.environment,
    this.defaultLanguage = 'en',
    this.defaultPalette = 'classic',
    this.defaultBrightness = 'light',
    this.preferredOrientations = const [DeviceOrientation.portraitUp],
  });

  final Environment environment;
  final String defaultLanguage;
  final String defaultPalette;
  final String defaultBrightness;
  final List<DeviceOrientation> preferredOrientations;

  bool get isProduction => environment == Environment.prod;
}
