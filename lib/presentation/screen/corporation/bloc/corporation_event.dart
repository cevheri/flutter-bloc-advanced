part of 'corporation_bloc.dart';

class CorporationEvent extends Equatable {
  const CorporationEvent();

  @override
  List<Object> get props => [];
}

class CorporationLoadList extends CorporationEvent {}

class CorporationCreate extends CorporationEvent {
  const CorporationCreate({
    required this.corporation,
  });

  final Corporation corporation;

  @override
  List<Object> get props => [corporation];
}

class CorporationUpdate extends CorporationEvent {
  const CorporationUpdate({
    required this.corporation,
  });

  final Corporation corporation;

  @override
  List<Object> get props => [corporation];
}

class CorporationEditEvent extends CorporationEvent {
  const CorporationEditEvent({
    required this.corporation,
  });

  final Corporation corporation;

  @override
  List<Object> get props => [corporation];
}

class CorporationSearch extends CorporationEvent {}
