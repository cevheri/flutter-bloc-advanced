part of 'district_bloc.dart';

/// District status used the success or failure of the authority loading.
enum DistrictStatus { initial, loading, success, failure }

/// District state that contains the current authority and the status of the authority.
/// The status is used to display the loading indicator.
///
/// The state is immutable and copyWith is used to update the state.
class DistrictState extends Equatable {
  final List<District?>? districts;
  final DistrictStatus status;

  const DistrictState({this.districts, this.status = DistrictStatus.initial});

  DistrictState copyWith({List<District>? districts, DistrictStatus? status}) {
    return DistrictState(status: status ?? this.status, districts: districts ?? districts);
  }

  @override
  List<Object> get props => [status, districts ?? []];

  @override
  bool get stringify => true;
}

class DistrictInitialState extends DistrictState {
  const DistrictInitialState() : super(status: DistrictStatus.initial);
}

class DistrictLoadingState extends DistrictState {
  const DistrictLoadingState() : super(status: DistrictStatus.loading);
}

class DistrictLoadSuccessState extends DistrictState {
  const DistrictLoadSuccessState({required super.districts}) : super(status: DistrictStatus.success);
}

class DistrictLoadFailureState extends DistrictState {
  final String message;

  const DistrictLoadFailureState({required this.message}) : super(status: DistrictStatus.failure);

  @override
  List<Object> get props => [status, message];
}
