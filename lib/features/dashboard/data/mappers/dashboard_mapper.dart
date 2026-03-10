import 'package:flutter_bloc_advance/features/dashboard/data/models/dashboard_model.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';

class DashboardMapper {
  const DashboardMapper._();

  static DashboardEntity toEntity(DashboardModel model) {
    return DashboardEntity(
      summary: model.summary
          .map((item) => DashboardSummaryEntity(id: item.id, label: item.label, value: item.value, trend: item.trend))
          .toList(growable: false),
      activities: model.activities
          .map(
            (item) => DashboardActivityEntity(
              id: item.id,
              title: item.title,
              subtitle: item.subtitle,
              time: item.time,
              type: item.type,
            ),
          )
          .toList(growable: false),
      quickActions: model.quickActions
          .map((item) => DashboardQuickActionEntity(id: item.id, label: item.label, icon: item.icon))
          .toList(growable: false),
    );
  }
}
