part of 'district_bloc.dart';

class DistrictEvent extends Equatable {
  const DistrictEvent();

  @override
  List<Object> get props => [];
}

class DistrictLoad extends DistrictEvent {
  const DistrictLoad({required City city});

  @override
  List<Object> get props => [];
}

class DistrictLoadList extends DistrictEvent {
  const DistrictLoadList({
    required this.districtId,
  });

  final String districtId;

  @override
  List<Object> get props => [districtId];
}
