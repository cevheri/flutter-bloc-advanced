import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/features/dashboard/data/mappers/dashboard_mapper.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';

import '../models/dashboard_model.dart';

/// Mock implementation that reads JSON from assets for local/dev runs
class DashboardMockRepository implements IDashboardRepository {
  @override
  Future<DashboardEntity> fetch() async {
    final json = await rootBundle.loadString('assets/mock/dashboard.json');
    return DashboardMapper.toEntity(DashboardModel.fromJsonString(json));
  }
}
