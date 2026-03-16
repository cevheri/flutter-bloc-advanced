import 'dart:convert';

import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';

class AppConfigModel extends AppConfigEntity {
  const AppConfigModel({
    super.minimumVersion,
    super.latestVersion,
    super.maintenanceMode,
    super.maintenanceMessage,
    super.maintenanceEstimatedEnd,
    super.storeUrl,
    super.featureFlags,
  });

  static AppConfigModel fromJson(Map<String, dynamic> json) {
    final flagsRaw = json['featureFlags'] as Map<String, dynamic>?;
    final flags = flagsRaw?.map((k, v) => MapEntry(k, v == true)) ?? {};

    return AppConfigModel(
      minimumVersion: json['minimumVersion'] as String?,
      latestVersion: json['latestVersion'] as String?,
      maintenanceMode: json['maintenanceMode'] == true,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      maintenanceEstimatedEnd: json['maintenanceEstimatedEnd'] as String?,
      storeUrl: json['storeUrl'] as String?,
      featureFlags: flags,
    );
  }

  static AppConfigModel fromJsonString(String jsonString) {
    return fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      if (minimumVersion != null) 'minimumVersion': minimumVersion,
      if (latestVersion != null) 'latestVersion': latestVersion,
      'maintenanceMode': maintenanceMode,
      if (maintenanceMessage != null) 'maintenanceMessage': maintenanceMessage,
      if (maintenanceEstimatedEnd != null) 'maintenanceEstimatedEnd': maintenanceEstimatedEnd,
      if (storeUrl != null) 'storeUrl': storeUrl,
      if (featureFlags.isNotEmpty) 'featureFlags': featureFlags,
    };
  }
}
