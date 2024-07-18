part of 'station_bloc.dart';

enum StationStatus { initial, loading, loaded, failure }

class StationState {
  final Station? user;
  final StationStatus status;

  const StationState({
    this.user,
    this.status = StationStatus.initial,
  });

  StationState copyWith({
    Station? user,
    StationStatus? status,
  }) {
    return StationState(status: status ?? this.status, user: user ?? this.user);
  }
}
class StationInitialState extends StationState {}

class StationLoadInProgressState extends StationState {}

class StationLoadSuccessState extends StationState {
  final Station station;

  const StationLoadSuccessState({required this.station});
}

class StationLoadFailureState extends StationState {
  final String message;

  const StationLoadFailureState({required this.message});
}

class StationCreateInitialState extends StationState {}

class StationCreateInProgressState extends StationState {}

class StationCreateSuccessState extends StationState {
  final Station station;

  const StationCreateSuccessState({required this.station});
}

class StationCreateFailureState extends StationState {
  final String message;

  const StationCreateFailureState({required this.message});
}

class StationListInitialState extends StationState {}

class StationListInProgressState extends StationState {}

class StationListSuccessState extends StationState {
  final List<Station> stationList;

  const StationListSuccessState({required this.stationList});
}

class StationListFailureState extends StationState {
  final String message;

  const StationListFailureState({required this.message});
}

class StationSearchSuccessState extends StationState {
  final List<Station> stationList;

  const StationSearchSuccessState({required this.stationList});
}

class StationUpdateInitialState extends StationState {}

class StationUpdateSuccessState extends StationState {
  final Station station;

  const StationUpdateSuccessState({required this.station});
}

class StationUpdateFailureState extends StationState {
  final String message;

  const StationUpdateFailureState({required this.message});
}




class StationListWithCorporationInitialState extends StationState {}

class StationListWithCorporationSuccessState extends StationState {
  final List<Station> stationList;

  const StationListWithCorporationSuccessState({required this.stationList});
}

class StationListWithCorporationFailureState extends StationState {
  final String message;

  const StationListWithCorporationFailureState({required this.message});
}