import 'package:equatable/equatable.dart';

class DashboardSummaryEntity extends Equatable {
  const DashboardSummaryEntity({
    required this.id,
    required this.label,
    required this.value,
    required this.trend,
  });

  final String id;
  final String label;
  final num value;
  final int trend;

  @override
  List<Object?> get props => [id, label, value, trend];
}

class DashboardActivityEntity extends Equatable {
  const DashboardActivityEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime time;
  final String type;

  @override
  List<Object?> get props => [id, title, subtitle, time, type];
}

class DashboardQuickActionEntity extends Equatable {
  const DashboardQuickActionEntity({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final String icon;

  @override
  List<Object?> get props => [id, label, icon];
}

class DashboardEntity extends Equatable {
  const DashboardEntity({
    required this.summary,
    required this.activities,
    required this.quickActions,
  });

  final List<DashboardSummaryEntity> summary;
  final List<DashboardActivityEntity> activities;
  final List<DashboardQuickActionEntity> quickActions;

  @override
  List<Object?> get props => [summary, activities, quickActions];
}
