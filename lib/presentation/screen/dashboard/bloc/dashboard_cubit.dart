import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/models/dashboard_model.dart';
import '../../../../data/repository/dashboard_repository.dart';

part 'dashboard_state.dart';

/// Cubit for dashboard screen
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repository;

  DashboardCubit({required this.repository}) : super(const DashboardState.initial());

  Future<void> load() async {
    emit(const DashboardState.loading());
    try {
      final model = await repository.fetch();
      emit(DashboardState.loaded(model));
    } catch (e) {
      emit(DashboardState.error(e.toString()));
    }
  }
}
