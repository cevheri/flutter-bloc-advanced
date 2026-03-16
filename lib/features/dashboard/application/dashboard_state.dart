part of 'dashboard_cubit.dart';

/// Status of the system dashboard.
enum SystemDashboardStatus { initial, loading, loaded, error }

/// State for the system dashboard cubit.
class SystemDashboardState extends Equatable {
  const SystemDashboardState({
    this.status = SystemDashboardStatus.initial,
    this.connectivity = ConnectivityStatus.online,
    this.circuitBreakerTotal = 0,
    this.circuitBreakerOpen = 0,
    this.cacheItemCount = 0,
    this.featureFlagsOn = 0,
    this.featureFlagsTotal = 0,
    this.endpointHealthList = const [],
    this.featureFlags = const {},
    this.appConfig = const AppConfigSummary(),
    this.interceptors = const [],
    this.errorMessage,
  });

  final SystemDashboardStatus status;
  final ConnectivityStatus connectivity;
  final int circuitBreakerTotal;
  final int circuitBreakerOpen;
  final int cacheItemCount;
  final int featureFlagsOn;
  final int featureFlagsTotal;
  final List<EndpointHealth> endpointHealthList;
  final Map<String, bool> featureFlags;
  final AppConfigSummary appConfig;
  final List<InterceptorInfo> interceptors;
  final String? errorMessage;

  SystemDashboardState copyWith({
    SystemDashboardStatus? status,
    ConnectivityStatus? connectivity,
    int? circuitBreakerTotal,
    int? circuitBreakerOpen,
    int? cacheItemCount,
    int? featureFlagsOn,
    int? featureFlagsTotal,
    List<EndpointHealth>? endpointHealthList,
    Map<String, bool>? featureFlags,
    AppConfigSummary? appConfig,
    List<InterceptorInfo>? interceptors,
    String? errorMessage,
  }) {
    return SystemDashboardState(
      status: status ?? this.status,
      connectivity: connectivity ?? this.connectivity,
      circuitBreakerTotal: circuitBreakerTotal ?? this.circuitBreakerTotal,
      circuitBreakerOpen: circuitBreakerOpen ?? this.circuitBreakerOpen,
      cacheItemCount: cacheItemCount ?? this.cacheItemCount,
      featureFlagsOn: featureFlagsOn ?? this.featureFlagsOn,
      featureFlagsTotal: featureFlagsTotal ?? this.featureFlagsTotal,
      endpointHealthList: endpointHealthList ?? this.endpointHealthList,
      featureFlags: featureFlags ?? this.featureFlags,
      appConfig: appConfig ?? this.appConfig,
      interceptors: interceptors ?? this.interceptors,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    connectivity,
    circuitBreakerTotal,
    circuitBreakerOpen,
    cacheItemCount,
    featureFlagsOn,
    featureFlagsTotal,
    endpointHealthList,
    featureFlags,
    appConfig,
    interceptors,
    errorMessage,
  ];
}

/// Health status of a single endpoint's circuit breaker.
class EndpointHealth extends Equatable {
  const EndpointHealth({required this.endpoint, required this.state, this.failureCount = 0, this.lastFailure});

  final String endpoint;
  final CircuitBreakerState state;
  final int failureCount;
  final DateTime? lastFailure;

  @override
  List<Object?> get props => [endpoint, state, failureCount, lastFailure];
}

/// Summary of the remote app configuration.
class AppConfigSummary extends Equatable {
  const AppConfigSummary({
    this.currentVersion = '0.0.0',
    this.minimumVersion = '-',
    this.maintenanceMode = false,
    this.environment = 'dev',
  });

  final String currentVersion;
  final String minimumVersion;
  final bool maintenanceMode;
  final String environment;

  @override
  List<Object?> get props => [currentVersion, minimumVersion, maintenanceMode, environment];
}

/// Metadata about a single interceptor in the Dio chain.
class InterceptorInfo extends Equatable {
  const InterceptorInfo({required this.name, required this.order, this.active = true, this.detail = ''});

  final String name;
  final int order;
  final bool active;
  final String detail;

  @override
  List<Object?> get props => [name, order, active, detail];
}
