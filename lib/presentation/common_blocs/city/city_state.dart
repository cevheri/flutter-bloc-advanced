part of 'city_bloc.dart';

/// City status used the success or failure of the authorities loading.
enum CityStatus { initial, loading, success, failure }

/// City state that contains the current authorities and the status of the authorities.
/// The status is used to display the loading indicator.
///
/// The state is immutable and copyWith is used to update the state.
class CityState extends Equatable {
  final List<City>? city;
  final CityStatus status;

  const CityState({
    this.city,
    this.status = CityStatus.initial,
  });

  CityState copyWith({
    List<City>? authorities,
    CityStatus? status,
  }) {
    return CityState(
        status: status ?? this.status, city: authorities ?? this.city);
  }

  @override
  List<Object> get props => [status];

  @override
  bool get stringify => true;
}

class CityInitialState extends CityState {}

class CityLoadSuccessState extends CityState {
  final List<City> city;

  const CityLoadSuccessState({required this.city});

  @override
  List<Object> get props => [city];
}

class CityLoadFailureState extends CityState {
  final String message;

  const CityLoadFailureState({required this.message});
}
