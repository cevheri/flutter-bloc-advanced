import 'package:flutter_bloc_advance/infrastructure/config/template_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static const String appName = TemplateConfig.appName;
  static String appVersion = "1.0.0";
  static String appBuildNumber = "1";

  static Future<void> initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    appVersion = info.version;
    appBuildNumber = info.buildNumber;
  }
}
