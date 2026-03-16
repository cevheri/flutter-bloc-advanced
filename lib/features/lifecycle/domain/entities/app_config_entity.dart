import 'package:equatable/equatable.dart';

/// Remote app configuration for lifecycle management.
class AppConfigEntity extends Equatable {
  const AppConfigEntity({
    this.minimumVersion,
    this.latestVersion,
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.maintenanceEstimatedEnd,
    this.storeUrl,
    this.featureFlags = const {},
  });

  /// Minimum app version required — below this triggers force update.
  final String? minimumVersion;

  /// Latest available version in the store.
  final String? latestVersion;

  /// Whether the app is in maintenance mode.
  final bool maintenanceMode;

  /// Custom message to show during maintenance.
  final String? maintenanceMessage;

  /// Estimated maintenance end time.
  final String? maintenanceEstimatedEnd;

  /// Store URL for force update redirect.
  final String? storeUrl;

  /// Runtime feature flags.
  final Map<String, bool> featureFlags;

  @override
  List<Object?> get props => [
    minimumVersion,
    latestVersion,
    maintenanceMode,
    maintenanceMessage,
    maintenanceEstimatedEnd,
    storeUrl,
    featureFlags,
  ];
}
