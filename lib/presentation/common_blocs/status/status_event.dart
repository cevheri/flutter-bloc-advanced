part of 'status_bloc.dart';

class StatusEvent extends Equatable {
  const StatusEvent();

  @override
  List<Object> get props => [];
}

class StatusLoadList extends StatusEvent {
  const StatusLoadList();

  @override
  List<Object> get props => [];
}

class StatusListWithOffer extends StatusEvent {
  final String offerStatusId;

  const StatusListWithOffer({required this.offerStatusId});

  @override
  List<Object> get props => [offerStatusId];
}
