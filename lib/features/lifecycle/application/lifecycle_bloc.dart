import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';

class LifecycleBloc extends Bloc<LifecycleEvent, LifecycleState> {
  LifecycleBloc({required ILifecycleRepository repository}) : _repository = repository, super(const LifecycleState()) {
    on<LifecycleCheckEvent>(_onCheck);
    on<LifecycleDismissUpdateEvent>(_onDismissUpdate);
  }

  static final _log = AppLogger.getLogger('LifecycleBloc');

  final ILifecycleRepository _repository;

  FutureOr<void> _onCheck(LifecycleCheckEvent event, Emitter<LifecycleState> emit) async {
    _log.debug('Checking app lifecycle config');
    emit(state.copyWith(status: LifecycleStatus.loading));

    final result = await _repository.fetchAppConfig();

    switch (result) {
      case Success(:final data):
        // Update feature flags
        if (data.featureFlags.isNotEmpty) {
          FeatureFlagService.instance.updateFlags(data.featureFlags);
        }

        // Check maintenance mode first
        if (data.maintenanceMode) {
          _log.info('App is in maintenance mode');
          emit(state.copyWith(status: LifecycleStatus.maintenance, config: data));
          return;
        }

        // Check force update
        if (data.minimumVersion != null && _isVersionBelow(AppConstants.appVersion, data.minimumVersion!)) {
          _log.info('Force update required: current={}, minimum={}', [AppConstants.appVersion, data.minimumVersion]);
          emit(state.copyWith(status: LifecycleStatus.forceUpdate, config: data));
          return;
        }

        // All clear
        emit(state.copyWith(status: LifecycleStatus.ready, config: data));

      case Failure(:final error):
        _log.warn('Failed to fetch app config: {}', [error.message]);
        // On failure, allow the app to proceed (graceful degradation)
        emit(state.copyWith(status: LifecycleStatus.ready, error: error.message));
    }
  }

  FutureOr<void> _onDismissUpdate(LifecycleDismissUpdateEvent event, Emitter<LifecycleState> emit) {
    emit(state.copyWith(status: LifecycleStatus.ready));
  }

  /// Compare semantic versions. Returns true if [current] < [minimum].
  bool _isVersionBelow(String current, String minimum) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minimumParts = minimum.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final m = i < minimumParts.length ? minimumParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
      return false; // Equal versions
    } catch (e) {
      _log.error('Version comparison failed: {} vs {}', [current, minimum]);
      return false;
    }
  }
}
