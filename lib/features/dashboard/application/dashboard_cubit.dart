import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/usecases/load_dashboard_usecase.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';

part 'dashboard_state.dart';

/// Cubit for dashboard screen
class DashboardCubit extends Cubit<DashboardState> {
  final LoadDashboardUseCase _loadDashboardUseCase;

  DashboardCubit({LoadDashboardUseCase? loadDashboardUseCase, IDashboardRepository? repository})
    : _loadDashboardUseCase = loadDashboardUseCase ?? LoadDashboardUseCase(repository!),
      super(const DashboardState.initial());

  Future<void> load() async {
    emit(const DashboardState.loading());
    final result = await _loadDashboardUseCase();
    switch (result) {
      case Success(:final data):
        emit(DashboardState.loaded(data));
      case Failure(:final error):
        emit(DashboardState.error(error.message));
    }
  }
}
