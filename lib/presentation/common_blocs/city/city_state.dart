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

  const CityState({this.cities, this.status = CityStatus.initial});

  CityState copyWith({List<City?>? cities, CityStatus? status}) {
    return CityState(status: status ?? this.status, cities: cities ?? this.cities);
  }

  @override
  List<Object> get props => [status, cities ?? []];

  @override
  bool get stringify => true;
}

class CityInitialState extends CityState {
  const CityInitialState() : super(status: CityStatus.initial);
}

class CityLoadingState extends CityState {
  const CityLoadingState() : super(status: CityStatus.loading);
}

class CityLoadSuccessState extends CityState {
  const CityLoadSuccessState({required List<City?> cities}) : super(cities: cities, status: CityStatus.success);
}

class CityLoadFailureState extends CityState {
  final String message;

  const CityLoadFailureState({required this.message}) : super(status: CityStatus.failure);

  @override
  List<Object> get props => [status, message];
}
