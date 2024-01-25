part of 'status_bloc.dart';

/// Status set used the success or failure of the authorities loading.
enum StatusSet { initial, loading, success, failure }

/// Status state that contains the current authorities and the set of the authorities.
/// The set is used to display the loading indicator.
///
/// The state is immutable and copyWith is used to update the state.
class StatusState extends Equatable {
  final List<Status>? status;
  final StatusSet set;

  const StatusState({
    this.status,
    this.set = StatusSet.initial,
  });

  StatusState copyWith({
    List<Status>? authorities,
    StatusSet? set,
  }) {
    return StatusState(set: set ?? this.set, status: authorities ?? this.status);
  }

  @override
  List<Object> get props => [set];

  @override
  bool get stringify => true;
}

class StatusInitialState extends StatusState {}

class StatusWithOfferInitialState extends StatusState {}

class StatusLoadSuccessState extends StatusState {
  final List<Status> statusLoaded;

  const StatusLoadSuccessState({required this.statusLoaded});

  @override
  List<Object> get props => [statusLoaded];
}

class StatusWithOfferLoadSuccessState extends StatusState {
  final List<Status> statusList;

  const StatusWithOfferLoadSuccessState({required this.statusList});

  @override
  List<Object> get props => [statusList];
}

class StatusLoadFailureState extends StatusState {
  final String message;

  const StatusLoadFailureState({required this.message});
}

class StatusWithOfferLoadFailureState extends StatusState {
  final String message;

  const StatusWithOfferLoadFailureState({required this.message});
}

