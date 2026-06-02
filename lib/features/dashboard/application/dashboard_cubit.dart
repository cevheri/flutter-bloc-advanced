import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';

part 'dashboard_state.dart';

/// Cubit that aggregates system-level metrics for the admin dashboard.
///
/// Collects data from [ConnectivityService], [FeatureFlagService],
/// [ResilienceInterceptor] (circuit breakers), and [SharedPrefsCacheStorage].
class SystemDashboardCubit extends Cubit<SystemDashboardState> {
  SystemDashboardCubit({
    required this._connectivityService,
    required this._featureFlagService,
    required this._resilienceInterceptor,
    required this._cacheStorage,
    required this._apiClient,
  }) : super(const SystemDashboardState()) {
    _connectivitySubscription = _connectivityService.statusStream.listen(_onConnectivityChanged);
    _featureFlagService.addListener(_onFeatureFlagsChanged);
  }

  static final _log = AppLogger.getLogger('SystemDashboardCubit');

  final ConnectivityService _connectivityService;
  final FeatureFlagService _featureFlagService;
  final ResilienceInterceptor _resilienceInterceptor;
  final SharedPrefsCacheStorage _cacheStorage;
  final ApiClient _apiClient;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  // ---------------------------------------------------------------------------
  // Reactive listeners
  // ---------------------------------------------------------------------------

  void _onConnectivityChanged(ConnectivityStatus status) {
    if (isClosed) return;
    _log.debug('Connectivity changed: {}', [status.name]);
    emit(state.copyWith(connectivity: status));
  }

  void _onFeatureFlagsChanged() {
    if (isClosed) return;
    _log.debug('Feature flags changed');
    final flags = _featureFlagService.allFlags;
    emit(
      state.copyWith(
        featureFlags: flags,
        featureFlagsTotal: flags.length,
        featureFlagsOn: flags.values.where((v) => v).length,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Load a full snapshot of all system metrics.
  Future<void> load() async {
    emit(state.copyWith(status: SystemDashboardStatus.loading));

    try {
      // Connectivity
      final connectivity = _connectivityService.currentStatus;

      // Circuit breakers
      final breakers = _resilienceInterceptor.circuitBreakers;
      final endpointHealthList = breakers.entries.map((e) {
        final cb = e.value;
        return EndpointHealth(
          endpoint: e.key,
          state: cb.state,
          failureCount: cb.failureCount,
          lastFailure: cb.lastFailureTime,
        );
      }).toList();
      final openCount = endpointHealthList.where((h) => h.state == CircuitBreakerState.open).length;

      // Cache
      final cacheCount = await _cacheStorage.count();

      // Feature flags
      final flags = _featureFlagService.allFlags;
      final flagsOn = flags.values.where((v) => v).length;

      // Interceptor chain
      final interceptors = _buildInterceptorList();

      emit(
        state.copyWith(
          status: SystemDashboardStatus.loaded,
          connectivity: connectivity,
          circuitBreakerTotal: endpointHealthList.length,
          circuitBreakerOpen: openCount,
          cacheItemCount: cacheCount,
          featureFlagsOn: flagsOn,
          featureFlagsTotal: flags.length,
          endpointHealthList: endpointHealthList,
          featureFlags: flags,
          interceptors: interceptors,
          clearErrorMessage: true,
        ),
      );

      _log.info('Dashboard loaded: {} endpoints, {} cached, {} flags', [
        endpointHealthList.length,
        cacheCount,
        flags.length,
      ]);
    } catch (e, st) {
      _log.error('Failed to load dashboard: {}', [e]);
      _log.debug('Stack trace: {}', [st]);
      emit(state.copyWith(status: SystemDashboardStatus.error, errorMessage: e.toString()));
    }
  }

  /// Update the app config summary (bridged from LifecycleBloc).
  void updateAppConfig(AppConfigSummary config) {
    emit(state.copyWith(appConfig: config));
  }

  /// Toggle a feature flag on/off.
  void toggleFeatureFlag(String key, bool value) {
    _featureFlagService.setFlag(key, value);
    // The ChangeNotifier callback will update state reactively.
  }

  /// Clear all cached data and reload.
  Future<void> clearCache() async {
    await _cacheStorage.clear();
    _log.info('Cache cleared via dashboard action');
    await load();
  }

  /// Reset all circuit breakers to closed and reload.
  Future<void> resetCircuitBreakers() async {
    _resilienceInterceptor.resetAll();
    _log.info('Circuit breakers reset via dashboard action');
    await load();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Snapshot of the live interceptor chain. Pulled from
  /// [ApiClient.interceptorChainSnapshot] (instance getter) so the
  /// dashboard cannot drift out of sync when interceptors are added,
  /// removed, or conditionally included (fixes #64).
  List<InterceptorInfo> _buildInterceptorList() {
    final snapshot = _apiClient.interceptorChainSnapshot;
    return [
      for (var i = 0; i < snapshot.length; i++)
        InterceptorInfo(name: snapshot[i].name, order: i + 1, active: snapshot[i].active, detail: snapshot[i].detail),
    ];
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _featureFlagService.removeListener(_onFeatureFlagsChanged);
    return super.close();
  }
}
