import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';

sealed class LifecycleState extends Equatable {
  const LifecycleState();
}

final class LifecycleInitial extends LifecycleState {
  const LifecycleInitial();

  @override
  List<Object?> get props => const [];
}

final class LifecycleLoading extends LifecycleState {
  const LifecycleLoading();

  @override
  List<Object?> get props => const [];
}

/// App is allowed to render normally.
///
/// [config] is present when the remote config fetch succeeded.
/// [error] is present when the fetch failed but the app is degrading
/// gracefully (we still proceed instead of blocking the user).
final class LifecycleReady extends LifecycleState {
  const LifecycleReady({this.config, this.error});

  final AppConfigEntity? config;
  final String? error;

  @override
  List<Object?> get props => [config, error];
}

/// App is blocked behind a "maintenance mode" screen.
final class LifecycleMaintenance extends LifecycleState {
  const LifecycleMaintenance({required this.config});

  final AppConfigEntity config;

  @override
  List<Object?> get props => [config];
}

/// App is blocked behind a "force update" screen.
final class LifecycleForceUpdate extends LifecycleState {
  const LifecycleForceUpdate({required this.config});

  final AppConfigEntity config;

  @override
  List<Object?> get props => [config];
}
