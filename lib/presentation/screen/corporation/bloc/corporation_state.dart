part of 'corporation_bloc.dart';

enum CorporationStatus { initial, loading, success, failure }

class CorporationState {
  final Corporation? corporation;
  final CorporationStatus status;

  const CorporationState({
    this.corporation,
    this.status = CorporationStatus.initial,
  });

  CorporationState copyWith({
    Corporation? corporation,
    CorporationStatus? status,
  }) {
    return CorporationState(status: status ?? this.status, corporation: corporation ?? this.corporation);
  }
}
class CorporationCreateInitialState extends CorporationState {}
class CorporationInitialState extends CorporationState {}
class CorporationEditInitialState extends CorporationState {}

class CorporationFindInitialState extends CorporationState {}

class CorporationLoadInProgressState extends CorporationState {}

class CorporationLoadSuccessState extends CorporationState {
  final Corporation corporation;

  const CorporationLoadSuccessState({required this.corporation});
}
class CorporationCreateSuccessState extends CorporationState {
  final Corporation corporation;

  const CorporationCreateSuccessState({required this.corporation});
}

class CorporationEditSuccessState extends CorporationState {
  final Corporation corporation;

  const CorporationEditSuccessState({required this.corporation});
}

class CorporationSearchSuccessState extends CorporationState {
  final List<Corporation> corporationList;

  const CorporationSearchSuccessState({required this.corporationList});
}

class CorporationLoadFailureState extends CorporationState {
  final String message;

  const CorporationLoadFailureState({required this.message});
}
class CorporationEditFailureState extends CorporationState {
  final String message;

  const CorporationEditFailureState({required this.message});
}

class CorporationSearchFailureState extends CorporationState {
  final String message;

  const CorporationSearchFailureState({required this.message});
}
class CorporationCreateFailureState extends CorporationState {
  final String message;

  const CorporationCreateFailureState({required this.message});
}


class CorporationListInitialState extends CorporationState {}

class CorporationListSuccessState extends CorporationState {
  final List<Corporation> corporationList;

  const CorporationListSuccessState({required this.corporationList});
}

class CorporationListFailureState extends CorporationState {
  final String message;

  const CorporationListFailureState({required this.message});
}

class CorporationUpdateInitialState extends CorporationState {}

class CorporationUpdateSuccessState extends CorporationState {
  final Corporation corporation;

  const CorporationUpdateSuccessState({required this.corporation});
}

class CorporationUpdateFailureState extends CorporationState {
  final String message;

  const CorporationUpdateFailureState({required this.message});
}