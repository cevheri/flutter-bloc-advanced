import 'package:equatable/equatable.dart';

class LifecycleEvent extends Equatable {
  const LifecycleEvent();
  @override
  List<Object> get props => [];
}

/// Fetch remote app configuration.
class LifecycleCheckEvent extends LifecycleEvent {
  const LifecycleCheckEvent();
}

/// Dismiss a soft-update notice (user chose to skip).
class LifecycleDismissUpdateEvent extends LifecycleEvent {
  const LifecycleDismissUpdateEvent();
}
