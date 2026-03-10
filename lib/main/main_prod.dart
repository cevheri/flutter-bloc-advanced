import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_bootstrap_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';

/// main entry point of PRODUCTION
void main() async {
  await AppBootstrap.run(
    const AppBootstrapConfig(
      environment: Environment.prod,
      defaultLanguage: 'en',
      defaultPalette: 'classic',
      defaultBrightness: 'dark',
    ),
  );
}
