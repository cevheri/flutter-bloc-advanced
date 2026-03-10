import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';

/// main entry point of local computer development
void main() async {
  await AppBootstrap.run(
    const AppBootstrapConfig(
      environment: Environment.dev,
      defaultLanguage: 'en',
      defaultPalette: 'classic',
      defaultBrightness: 'light',
    ),
  );
}
