import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';

abstract class IDashboardRepository {
  Future<Result<DashboardEntity>> fetch();
}
