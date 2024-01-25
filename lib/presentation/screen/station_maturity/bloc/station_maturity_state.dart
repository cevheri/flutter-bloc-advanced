part of 'station_maturity_bloc.dart';

enum StationMaturityStatus { initial, loading, loaded, failure }

class StationMaturityState {
  final StationMaturity? user;
  final StationMaturityStatus status;

  const StationMaturityState({
    this.user,
    this.status = StationMaturityStatus.initial,
  });

  StationMaturityState copyWith({
    StationMaturity? user,
    StationMaturityStatus? status,
  }) {
    return StationMaturityState(
        status: status ?? this.status, user: user ?? this.user);
  }
}

class StationMaturityInitialState extends StationMaturityState {}

class StationMaturityLoadInProgressState extends StationMaturityState {}

class StationMaturityLoadSuccessState extends StationMaturityState {
  final List<StationMaturity> stationMaturity;
  final List<Maturity> maturity;

  const StationMaturityLoadSuccessState({required this.stationMaturity, required this.maturity});
}

class StationMaturityLoadFailureState extends StationMaturityState {
  final String message;

  const StationMaturityLoadFailureState({required this.message});
}

class StationMaturityCreateInitialState extends StationMaturityState {}

class StationMaturityCreateInProgressState extends StationMaturityState {}

class StationMaturityCreateSuccessState extends StationMaturityState {
  final StationMaturity stationMaturity;

  const StationMaturityCreateSuccessState({required this.stationMaturity});
}

class StationMaturityCreateFailureState extends StationMaturityState {
  final String message;

  const StationMaturityCreateFailureState({required this.message});
}

class StationMaturityDeleteInProgressState extends StationMaturityState {}

class StationMaturityDeleteSuccessState extends StationMaturityState {
  final bool stationMaturity;

  const StationMaturityDeleteSuccessState({required this.stationMaturity});
}

class StationMaturityDeleteFailureState extends StationMaturityState {
  final String message;

  const StationMaturityDeleteFailureState({required this.message});
}


class StationMaturityUpdateInProgressState extends StationMaturityState {}

class StationMaturityUpdateSuccessState extends StationMaturityState {
  final StationMaturity stationMaturity;

  const StationMaturityUpdateSuccessState({required this.stationMaturity});
}

class StationMaturityUpdateFailureState extends StationMaturityState {
  final String message;

  const StationMaturityUpdateFailureState({required this.message});
}