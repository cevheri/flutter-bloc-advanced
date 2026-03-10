import 'dart:convert';

import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';

/// Dashboard summary KPI item model
class DashboardSummary extends DashboardSummaryEntity {
  const DashboardSummary({required super.id, required super.label, required super.value, required super.trend});

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
    id: json['id'] as String,
    label: json['label'] as String,
    value: json['value'] as num,
    trend: (json['trend'] as num).toInt(),
  );

  static List<DashboardSummary> fromJsonList(List<dynamic> list) =>
      list.map((e) => DashboardSummary.fromJson(e)).toList();

}

/// Dashboard recent activity item model
class DashboardActivity extends DashboardActivityEntity {
  const DashboardActivity({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.time,
    required super.type,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) => DashboardActivity(
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    time: DateTime.parse(json['time'] as String),
    type: json['type'] as String,
  );

  static List<DashboardActivity> fromJsonList(List<dynamic> list) =>
      list.map((e) => DashboardActivity.fromJson(e)).toList();

}

/// Dashboard quick action item model
class DashboardQuickAction extends DashboardQuickActionEntity {
  const DashboardQuickAction({required super.id, required super.label, required super.icon});

  factory DashboardQuickAction.fromJson(Map<String, dynamic> json) =>
      DashboardQuickAction(id: json['id'] as String, label: json['label'] as String, icon: json['icon'] as String);

  static List<DashboardQuickAction> fromJsonList(List<dynamic> list) =>
      list.map((e) => DashboardQuickAction.fromJson(e)).toList();

}

/// Dashboard root model
class DashboardModel extends DashboardEntity {
  const DashboardModel({required super.summary, required super.activities, required super.quickActions});

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
    summary: DashboardSummary.fromJsonList(json['summary'] as List<dynamic>),
    activities: DashboardActivity.fromJsonList(json['activities'] as List<dynamic>),
    quickActions: DashboardQuickAction.fromJsonList(json['quick_actions'] as List<dynamic>),
  );

  static DashboardModel fromJsonString(String jsonString) =>
      DashboardModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

}
