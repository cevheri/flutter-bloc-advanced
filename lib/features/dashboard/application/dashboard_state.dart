part of 'dashboard_cubit.dart';

/// Sealed-like state for dashboard using Equatable
class DashboardState extends Equatable {
  final DashboardEntity? model;
  final String? message;
  final DashboardStatus status;

  const DashboardState({required this.status, this.model, this.message});

  const DashboardState.initial() : this(status: DashboardStatus.initial);
  const DashboardState.loading() : this(status: DashboardStatus.loading);
  const DashboardState.error(String msg) : this(status: DashboardStatus.error, message: msg);
  const DashboardState.loaded(DashboardEntity m) : this(status: DashboardStatus.loaded, model: m);

  @override
  List<Object?> get props => [status, model, message];
}

enum DashboardStatus { initial, loading, loaded, error }
