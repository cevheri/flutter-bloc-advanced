import 'package:flutter/services.dart';

class AppConstants {
  static const String appKey = "flutter_bloc_advanced";
  static const String appName = "FlutterTemplate";
  static const String appVersion = "1.0.0";
  static const String appDescription = "User Roles and Offering Management mobile and web application";
  static const String appAuthor = "sekoya.tech";
  static const String appAuthorEmail = "info@sekoya.tech";
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
