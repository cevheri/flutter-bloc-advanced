part of 'refinery_bloc.dart';

enum RefineryStatus { initial, loading, success, failure }

class RefineryState {
  final Refinery? refinery;
  final RefineryStatus status;

  const RefineryState({
    this.refinery,
    this.status = RefineryStatus.initial,
  });

  RefineryState copyWith({
    Refinery? refinery,
    RefineryStatus? status,
  }) {
    return RefineryState(status: status ?? this.status, refinery: refinery ?? this.refinery);
  }
}

class RefineryInitialState extends RefineryState {}
class RefineryCreateInitialState extends RefineryState {}
class RefineryEditInitialState extends RefineryState {}

class RefineryFindInitialState extends RefineryState {}

class RefineryLoadInProgressState extends RefineryState {}

class RefineryLoadSuccessState extends RefineryState {
  final Refinery refinery;

  const RefineryLoadSuccessState({required this.refinery});
}

class RefineryCreateSuccessState extends RefineryState {
  final Refinery refinery;

  const RefineryCreateSuccessState({required this.refinery});
}

class RefineryEditSuccessState extends RefineryState {
  final Refinery refinery;

  const RefineryEditSuccessState({required this.refinery});
}

class RefinerySearchSuccessState extends RefineryState {
  final List<Refinery> refineryList;

  const RefinerySearchSuccessState({required this.refineryList});
}

class RefineryLoadFailureState extends RefineryState {
  final String message;

  const RefineryLoadFailureState({required this.message});
}

class RefineryCreateFailureState extends RefineryState {
  final String message;

  const RefineryCreateFailureState({required this.message});
}


class RefineryEditFailureState extends RefineryState {
  final String message;

  const RefineryEditFailureState({required this.message});
}

class RefinerySearchFailureState extends RefineryState {
  final String message;

  const RefinerySearchFailureState({required this.message});
}

class RefineryUpdateInitialState extends RefineryState {}

class RefineryUpdateSuccessState extends RefineryState {
  final Refinery refinery;

  const RefineryUpdateSuccessState({required this.refinery});
}

class RefineryUpdateFailureState extends RefineryState {
  final String message;

  const RefineryUpdateFailureState({required this.message});
}