part of 'refinery_bloc.dart';

class RefineryEvent extends Equatable {
  const RefineryEvent();

  @override
  List<Object> get props => [];
}

class RefinerySearch extends RefineryEvent {}

class RefineryCreate extends RefineryEvent {
  const RefineryCreate({
    required this.refinery,
  });

  final Refinery refinery;

  @override
  List<Object> get props => [];
}

class RefineryUpdate extends RefineryEvent {
  const RefineryUpdate({
    required this.refinery,
  });

  final Refinery refinery;

  @override
  List<Object> get props => [];
}

class RefineryEditEvent extends RefineryEvent {
  const RefineryEditEvent({
    required this.refinery,
  });

  final Refinery refinery;

  @override
  List<Object> get props => [];
}
