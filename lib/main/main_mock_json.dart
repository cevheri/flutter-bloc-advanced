
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configuration/environment.dart';
import '../utils/app_constants.dart';
import 'app.dart';
import 'main_local.mapper.g.dart' show initializeJsonMapper;

/// IMPORTANT!! run this command to generate main_prod.mapper.g.dart
// dart run build_runner build --delete-conflicting-outputs
// /home/cevheri/snap/flutter/common/flutter/bin/flutter --no-color pub global run intl_utils:generate

/// main entry point of local computer development with local mock json files(assets/mock/*.json)
void main() async {
  ProfileConstants.setEnvironment(Environment.MOCK_JSON);
  initializeJsonMapper();
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? language = prefs.getString('lang');
  if (language == null) {
    prefs.setString('lang', 'en');
    language = 'en';
  }
  AppConstants.jwtToken = prefs.getString('jwtToken') ?? "";
  AppConstants.role = prefs.getString('role') ?? "";

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_){
  runApp(App(language: language??'tr'));
  });
}