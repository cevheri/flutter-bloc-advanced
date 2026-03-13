import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dashboard/data/models/dashboard_model.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Mock implementation that reads JSON from assets for local/dev runs
class DashboardMockRepository implements IDashboardRepository {
  @override
  Future<Result<DashboardEntity>> fetch() async {
    try {
      final json = await rootBundle.loadString('assets/mock/dashboard.json');
      return Success(DashboardModel.fromJsonString(json));
    } catch (e, st) {
      return Failure(UnknownError(e.toString()), stackTrace: st);
    }
  }
}
