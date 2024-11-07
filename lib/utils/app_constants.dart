import 'package:flutter/services.dart';

class AppConstants {
  static const String APP_KEY = "flutter_bloc_advanced_api";
  static const String APP_NAME = "User-Offering-Management";
  static const String APP_VERSION = "1.0.0";
  static const String APP_DESCRIPTION = "User Roles and Offering Management mobile and web application";
  static const String APP_AUTHOR = "*****";
  static const String APP_AUTHOR_EMAIL = "*****@*****.com";
  // static String jwtToken = "";
  // static String role = "";
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
