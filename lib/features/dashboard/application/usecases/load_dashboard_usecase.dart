import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';

class LoadDashboardUseCase {
  const LoadDashboardUseCase(this._repository);

  final IDashboardRepository _repository;

  Future<DashboardEntity> call() {
    return _repository.fetch();
  }
}
