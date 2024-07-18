part of 'station_bloc.dart';

class StationEvent extends Equatable {
  const StationEvent();

  @override
  List<Object> get props => [];
}

class StationCreate extends StationEvent {
  const StationCreate({
    required this.station,
  });

  final Station station;

  @override
  List<Object> get props => [];
}

class StationWithCityIdList extends StationEvent {
  const StationWithCityIdList({
    required this.cityId,
  });

  final String cityId;

  @override
  List<Object> get props => [];
}

class StationSearch extends StationEvent {
  final String? corporationId;
  final String? cityId;

  const StationSearch({
    this.corporationId,
    this.cityId,
  });
}

class StationUpdate extends StationEvent {
  const StationUpdate({
    required this.station,
  });

  final Station station;

  @override
  List<Object> get props => [];
}

class StationListWithCorporation extends StationEvent {
  const StationListWithCorporation({
    required this.corporationId,
  });

  final String corporationId;

  @override
  List<Object> get props => [];
}
