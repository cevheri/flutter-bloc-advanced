part of 'district_bloc.dart';

/// District status used the success or failure of the authorities loading.
enum DistrictStatus { initial, loading, success, failure }

/// District state that contains the current authorities and the status of the authorities.
/// The status is used to display the loading indicator.
///
/// The state is immutable and copyWith is used to update the state.
class DistrictState extends Equatable {
  final List<District>? district;
  final DistrictStatus status;

  const DistrictState({
    this.district,
    this.status = DistrictStatus.initial,
  });

  DistrictState copyWith({
    List<District>? authorities,
    DistrictStatus? status,
  }) {
    return DistrictState(
        status: status ?? this.status, district: authorities ?? district);
  }

  @override
  List<Object> get props => [status];

  @override
  bool get stringify => true;
}

class DistrictInitialState extends DistrictState {}

class DistrictLoadSuccessState extends DistrictState {
  final List<District> districtList;

  const DistrictLoadSuccessState({required this.districtList});

  @override
  List<Object> get props => [districtList];
}

class DistrictLoadFailureState extends DistrictState {
  final String message;

  const DistrictLoadFailureState({required this.message});
}
