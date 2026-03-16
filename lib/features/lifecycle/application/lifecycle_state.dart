import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';

enum LifecycleStatus { initial, loading, ready, forceUpdate, maintenance, failure }

class LifecycleState extends Equatable {
  const LifecycleState({this.status = LifecycleStatus.initial, this.config, this.error});

  final LifecycleStatus status;
  final AppConfigEntity? config;
  final String? error;

  LifecycleState copyWith({LifecycleStatus? status, AppConfigEntity? config, String? error}) {
    return LifecycleState(status: status ?? this.status, config: config ?? this.config, error: error ?? this.error);
  }

  @override
  List<Object?> get props => [status, config, error];
}
