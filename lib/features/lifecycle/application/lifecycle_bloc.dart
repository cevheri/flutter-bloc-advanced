import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';
import 'package:flutter_bloc_advance/shared/utils/semver.dart';

/// Decides from the remote app config whether the app opens, shows the maintenance screen or asks for an update.
///
/// The app checks when it starts, when the user retries from the maintenance screen, and when it comes back to the
/// foreground, at most once per [defaultRecheckInterval]. A check that arrives while another runs is dropped.
///
/// A config that cannot be read opens the app (fail open) and is logged as an error. A failed re-check keeps a
/// maintenance or update screen the server asked for, so a server error or a lost connection does not let an
/// outdated app in.
class LifecycleBloc extends Bloc<LifecycleEvent, LifecycleState> {
  LifecycleBloc({
    required this._repository,
    required this._featureFlagService,
    this._recheckInterval = defaultRecheckInterval,
  }) : super(const LifecycleInitial()) {
    on<LifecycleCheckEvent>(_onCheck, transformer: EventTransformers.dropConcurrent());
  }

  static final _log = AppLogger.getLogger('LifecycleBloc');

  /// How long after a check the app waits before it checks again when it comes back to the foreground.
  static const defaultRecheckInterval = Duration(minutes: 5);

  final ILifecycleRepository _repository;
  final FeatureFlagService _featureFlagService;
  final Duration _recheckInterval;

  /// When the latest check started, by the wall clock, which keeps running while the app is in the background.
  DateTime? _lastCheckStartedAt;

  FutureOr<void> _onCheck(LifecycleCheckEvent event, Emitter<LifecycleState> emit) async {
    final now = clock.now();
    final lastCheckStartedAt = _lastCheckStartedAt;
    if (event.trigger == LifecycleCheckTrigger.resume &&
        lastCheckStartedAt != null &&
        now.difference(lastCheckStartedAt) < _recheckInterval) {
      _log.debug('Not checking the app config on resume: the last check started {} ago', [
        now.difference(lastCheckStartedAt),
      ]);
      return;
    }
    _lastCheckStartedAt = now;
    _log.debug('Checking the app config ({})', [event.trigger.name]);

    // A re-check keeps the screen the last answer chose until the new answer arrives.
    switch (state) {
      case LifecycleInitial():
        emit(const LifecycleLoading());
      case LifecycleMaintenance(:final config):
        emit(LifecycleMaintenance(config: config, checking: true));
      case LifecycleLoading() || LifecycleReady() || LifecycleForceUpdate():
        break;
    }

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
        final minimumVersion = data.minimumVersion;
        if (minimumVersion != null) {
          final bool updateRequired;
          try {
            updateRequired = Semver.isBelow(AppConstants.appVersion, minimumVersion);
          } on FormatException catch (e) {
            _onMalformedVersion(data, e, emit);
            return;
          }
          if (updateRequired) {
            _log.info('Force update required: current={}, minimum={}', [AppConstants.appVersion, minimumVersion]);
            emit(LifecycleForceUpdate(config: data));
            return;
          }
        }

        // All clear
        emit(LifecycleReady(config: data));

      case Failure(:final error):
        switch (state) {
          case LifecycleMaintenance(:final config):
            _log.error('Could not check the app config again, so the maintenance screen stays: {}', [error]);
            emit(LifecycleMaintenance(config: config));
          case LifecycleForceUpdate():
            _log.error('Could not check the app config again, so the update screen stays: {}', [error]);
          case LifecycleReady(:final config):
            _log.error('Could not check the app config again, so the app stays open: {}', [error]);
            emit(LifecycleReady(config: config, error: error));
          case LifecycleInitial() || LifecycleLoading():
            _log.error('Could not check the app config, so the app opens without it: {}', [error]);
            emit(LifecycleReady(error: error));
        }
    }
  }

  /// A version that does not parse fails open, as a failed check does: the app opens with the config and the error,
  /// and an update screen an earlier answer chose stays.
  void _onMalformedVersion(AppConfigEntity config, FormatException exception, Emitter<LifecycleState> emit) {
    final error = ValidationError(exception.message);
    switch (state) {
      case LifecycleForceUpdate():
        _log.error(
          'Could not compare app version {} with minimumVersion {} from the app config, so the update screen stays: {}',
          [AppConstants.appVersion, config.minimumVersion, error],
        );
      case LifecycleInitial() || LifecycleLoading() || LifecycleReady() || LifecycleMaintenance():
        _log.error(
          'Could not compare app version {} with minimumVersion {} from the app config, so the app opens: {}',
          [AppConstants.appVersion, config.minimumVersion, error],
        );
        emit(LifecycleReady(config: config, error: error));
    }
  }
}
