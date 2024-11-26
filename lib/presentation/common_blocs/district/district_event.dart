part of 'district_bloc.dart';

class DistrictEvent extends Equatable {
  const DistrictEvent();

  @override
  List<Object> get props => [];
}

class DistrictLoadByCity extends DistrictEvent {
  final String cityId;

  const DistrictLoadByCity({required this.cityId});

  @override
  List<Object> get props => [cityId];
}

class DistrictLoad extends DistrictEvent {
  const DistrictLoad();

  @override
  List<Object> get props => [];
}
