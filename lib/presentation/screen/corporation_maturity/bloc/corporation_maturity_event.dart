
part of 'corporation_maturity_bloc.dart';

class CorporationMaturityEvent extends Equatable {
  const CorporationMaturityEvent();

  @override
  List<Object> get props => [];
}


class CorporationMaturityCreate extends CorporationMaturityEvent {
  const CorporationMaturityCreate({
    required this.corporationMaturity,
  });

  final CorporationMaturity corporationMaturity;

  @override
  List<Object> get props => [corporationMaturity];
}

class CorporationMaturityLoad extends CorporationMaturityEvent {
  const CorporationMaturityLoad({
    required this.id,
  });

  final int id;

  @override
  List<Object> get props => [id];
}

class CorporationMaturityDelete extends CorporationMaturityEvent {
  const CorporationMaturityDelete({
    required this.id,
  });

  final int id;

  @override
  List<Object> get props => [id];
}

class CorporationMaturityUpdate extends CorporationMaturityEvent {
  const CorporationMaturityUpdate({
    required this.corporationMaturity,
  });

  final CorporationMaturity corporationMaturity;

  @override
  List<Object> get props => [corporationMaturity];
}