import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_bloc_advance/shared/utils/semver.dart';

class LifecycleBloc extends Bloc<LifecycleEvent, LifecycleState> {
  LifecycleBloc({required this._repository, required this._featureFlagService}) : super(const LifecycleInitial()) {
    on<LifecycleCheckEvent>(_onCheck);
    on<LifecycleDismissUpdateEvent>(_onDismissUpdate);
  }

  static final _log = AppLogger.getLogger('LifecycleBloc');

  final ILifecycleRepository _repository;
  final FeatureFlagService _featureFlagService;

  FutureOr<void> _onCheck(LifecycleCheckEvent event, Emitter<LifecycleState> emit) async {
    _log.debug('Checking app lifecycle config');
    emit(const LifecycleLoading());

    final result = await _repository.fetchAppConfig();

    switch (result) {
      case Success(:final data):
        // Update feature flags
        if (data.featureFlags.isNotEmpty) {
          _featureFlagService.updateFlags(data.featureFlags);
        }

        // Check maintenance mode first
        if (data.maintenanceMode) {
          _log.info('App is in maintenance mode');
          emit(LifecycleMaintenance(config: data));
          return;
        }

        // Check force update
        if (data.minimumVersion != null && Semver.isBelow(AppConstants.appVersion, data.minimumVersion!)) {
          _log.info('Force update required: current={}, minimum={}', [AppConstants.appVersion, data.minimumVersion]);
          emit(LifecycleForceUpdate(config: data));
          return;
        }

        // All clear
        emit(LifecycleReady(config: data));

      case Failure(:final error):
        _log.warn('Failed to fetch app config: {}', [error.message]);
        // On failure, allow the app to proceed (graceful degradation)
        emit(LifecycleReady(error: error.message));
    }
  }

  FutureOr<void> _onDismissUpdate(LifecycleDismissUpdateEvent event, Emitter<LifecycleState> emit) {
    final config = switch (state) {
      LifecycleMaintenance(:final config) => config,
      LifecycleForceUpdate(:final config) => config,
      LifecycleReady(:final config) => config,
      _ => null,
    };
    emit(LifecycleReady(config: config));
  }
}
