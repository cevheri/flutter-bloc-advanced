import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static const String appKey = TemplateConfig.appKey;
  static const String appName = TemplateConfig.appName;
  static String appVersion = "1.0.0";
  static String appBuildNumber = "1";
  static const String appDescription = TemplateConfig.appDescription;
  static const String appAuthor = TemplateConfig.authorName;
  static const String appAuthorEmail = TemplateConfig.authorEmail;

  static Future<void> initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    appVersion = info.version;
    appBuildNumber = info.buildNumber;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
