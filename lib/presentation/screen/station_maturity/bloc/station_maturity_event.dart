
part of 'station_maturity_bloc.dart';

class StationMaturityEvent extends Equatable {
  const StationMaturityEvent();

  @override
  List<Object> get props => [];
}


class StationMaturityCreate extends StationMaturityEvent {
  const StationMaturityCreate({
    required this.stationMaturity,
  });

  final StationMaturity stationMaturity;

  @override
  List<Object> get props => [];
}

class StationMaturityLoad extends StationMaturityEvent {
  const StationMaturityLoad({
    required this.id,
  });

  final int id;

  @override
  List<Object> get props => [];
}

class StationMaturityDelete extends StationMaturityEvent {
  const StationMaturityDelete({
    required this.id,
  });

  final int id;

  @override
  List<Object> get props => [];
}

class StationMaturityUpdate extends StationMaturityEvent {
  const StationMaturityUpdate({
    required this.stationMaturity,
  });

  final StationMaturity stationMaturity;

  @override
  List<Object> get props => [];
}