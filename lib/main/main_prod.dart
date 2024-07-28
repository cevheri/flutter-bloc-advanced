import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configuration/environment.dart';
import '../data/http_utils.dart';
import '../utils/app_constants.dart';
import 'app.dart';
import 'main_prod.mapper.g.dart' show initializeJsonMapper;

/// IMPORTANT!! run this command to generate main_prod.mapper.g.dart
// dart run build_runner build --delete-conflicting-outputs

/// main entry point of production environment
void main() async {
  HttpOverrides.global = MyHttpOverrides();
  ProfileConstants.setEnvironment(Environment.PROD);
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
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]).then((_){
    runApp(App(language: language??'tr'));
  });
}