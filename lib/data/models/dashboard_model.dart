import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Dashboard summary KPI item model
class DashboardSummary extends Equatable {
  final String id;
  final String label;
  final num value;
  final int trend; // +/- percent

  const DashboardSummary({required this.id, required this.label, required this.value, required this.trend});

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
    id: json['id'] as String,
    label: json['label'] as String,
    value: json['value'] as num,
    trend: (json['trend'] as num).toInt(),
  );

  static List<DashboardSummary> fromJsonList(List<dynamic> list) =>
      list.map((e) => DashboardSummary.fromJson(e)).toList();

  @override
  List<Object?> get props => [id, label, value, trend];
}

/// Dashboard recent activity item model
class DashboardActivity extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final DateTime time;
  final String type;

  const DashboardActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
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

  @override
  List<Object?> get props => [id, title, subtitle, time, type];
}

/// Dashboard quick action item model
class DashboardQuickAction extends Equatable {
  final String id;
  final String label;
  final String icon; // material icon name

  const DashboardQuickAction({required this.id, required this.label, required this.icon});

  factory DashboardQuickAction.fromJson(Map<String, dynamic> json) =>
      DashboardQuickAction(id: json['id'] as String, label: json['label'] as String, icon: json['icon'] as String);

  static List<DashboardQuickAction> fromJsonList(List<dynamic> list) =>
      list.map((e) => DashboardQuickAction.fromJson(e)).toList();

  @override
  List<Object?> get props => [id, label, icon];
}

/// Dashboard root model
class DashboardModel extends Equatable {
  final List<DashboardSummary> summary;
  final List<DashboardActivity> activities;
  final List<DashboardQuickAction> quickActions;

  const DashboardModel({required this.summary, required this.activities, required this.quickActions});

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
    summary: DashboardSummary.fromJsonList(json['summary'] as List<dynamic>),
    activities: DashboardActivity.fromJsonList(json['activities'] as List<dynamic>),
    quickActions: DashboardQuickAction.fromJsonList(json['quick_actions'] as List<dynamic>),
  );

  static DashboardModel fromJsonString(String jsonString) =>
      DashboardModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  @override
  List<Object?> get props => [summary, activities, quickActions];
}
