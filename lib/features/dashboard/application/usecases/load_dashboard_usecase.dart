import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';

class LoadDashboardUseCase {
  const LoadDashboardUseCase(this._repository);

  final IDashboardRepository _repository;

  Future<Result<DashboardEntity>> call() {
    return _repository.fetch();
  }
}
