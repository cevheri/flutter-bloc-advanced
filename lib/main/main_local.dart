import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import '../configuration/environment.dart';
import 'app.dart';
import 'main_local.mapper.g.dart' show initializeJsonMapper;

/// IMPORTANT!! run this command to generate main_prod.mapper.g.dart
// dart run build_runner build --delete-conflicting-outputs

/// main entry point of local computer development
void main() async {
  ProfileConstants.setEnvironment(Environment.DEV);
  initializeJsonMapper();
  WidgetsFlutterBinding.ensureInitialized();
  AdaptiveThemeMode? savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(App(savedThemeMode: savedThemeMode));
}
