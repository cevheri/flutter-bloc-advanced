import 'package:equatable/equatable.dart';

/// What started a check of the remote app configuration.
enum LifecycleCheckTrigger {
  /// The app started.
  launch,

  /// The user asked for one, from the maintenance screen.
  retry,

  /// The app came back to the foreground. It checks only when the last check started at least
  /// `LifecycleBloc.defaultRecheckInterval` ago.
  resume,
}

class LifecycleEvent extends Equatable {
  const LifecycleEvent();
  @override
  List<Object> get props => [];
}

/// Fetch remote app configuration.
class LifecycleCheckEvent extends LifecycleEvent {
  const LifecycleCheckEvent({this.trigger = LifecycleCheckTrigger.launch});

  final LifecycleCheckTrigger trigger;

  @override
  List<Object> get props => [trigger];
}

/// Dismiss a soft-update notice (user chose to skip).
class LifecycleDismissUpdateEvent extends LifecycleEvent {
  const LifecycleDismissUpdateEvent();
}
