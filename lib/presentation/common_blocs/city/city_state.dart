part of 'city_bloc.dart';

/// City status used the success or failure of the authority loading.
enum CityStatus { initial, loading, success, failure }

/// City state that contains the current authority and the status of the authority.
/// The status is used to display the loading indicator.
///
/// The state is immutable and copyWith is used to update the state.
class CityState extends Equatable {
  final List<City?>? cities;
  final CityStatus status;

  const CityState({
    this.cities,
    this.status = CityStatus.initial,
  });

  CityState copyWith({
    List<City?>? cities,
    CityStatus? status,
  }) {
    return CityState(status: status ?? this.status, cities: cities ?? this.cities);
  }

  @override
  List<Object> get props => [status];

  @override
  bool get stringify => true;
}

class CityInitialState extends CityState {}

class CityLoadSuccessState extends CityState {
  final List<City?> cities;

  const CityLoadSuccessState({required this.cities});

  @override
  List<Object> get props => [cities];
}

class CityLoadFailureState extends CityState {
  final String message;

  const CityLoadFailureState({required this.message});
}
