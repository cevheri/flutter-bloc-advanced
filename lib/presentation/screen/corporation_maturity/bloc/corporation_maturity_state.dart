part of 'corporation_maturity_bloc.dart';

enum CorporationMaturityStatus { initial, loading, loaded, failure }

class CorporationMaturityState {
  final CorporationMaturity? user;
  final CorporationMaturityStatus status;

  const CorporationMaturityState({
    this.user,
    this.status = CorporationMaturityStatus.initial,
  });

  CorporationMaturityState copyWith({
    CorporationMaturity? user,
    CorporationMaturityStatus? status,
  }) {
    return CorporationMaturityState(
        status: status ?? this.status, user: user ?? this.user);
  }
}

class CorporationMaturityInitialState extends CorporationMaturityState {}

class CorporationMaturityLoadInProgressState extends CorporationMaturityState {}

class CorporationMaturityLoadSuccessState extends CorporationMaturityState {
  final List<CorporationMaturity> corporationMaturity;
  final List<Maturity> maturity;

  const CorporationMaturityLoadSuccessState({required this.corporationMaturity, required this.maturity});
}

class CorporationMaturityLoadFailureState extends CorporationMaturityState {
  final String message;

  const CorporationMaturityLoadFailureState({required this.message});
}

class CorporationMaturityCreateInitialState extends CorporationMaturityState {}

class CorporationMaturityCreateInProgressState extends CorporationMaturityState {}

class CorporationMaturityCreateSuccessState extends CorporationMaturityState {
  final CorporationMaturity corporationMaturity;

  const CorporationMaturityCreateSuccessState({required this.corporationMaturity});
}

class CorporationMaturityCreateFailureState extends CorporationMaturityState {
  final String message;

  const CorporationMaturityCreateFailureState({required this.message});
}

class CorporationMaturityDeleteInProgressState extends CorporationMaturityState {}

class CorporationMaturityDeleteSuccessState extends CorporationMaturityState {
  final bool corporationMaturity;

  const CorporationMaturityDeleteSuccessState({required this.corporationMaturity});
}

class CorporationMaturityDeleteFailureState extends CorporationMaturityState {
  final String message;

  const CorporationMaturityDeleteFailureState({required this.message});
}


class CorporationMaturityUpdateInProgressState extends CorporationMaturityState {}

class CorporationMaturityUpdateSuccessState extends CorporationMaturityState {
  final CorporationMaturity corporationMaturity;

  const CorporationMaturityUpdateSuccessState({required this.corporationMaturity});
}

class CorporationMaturityUpdateFailureState extends CorporationMaturityState {
  final String message;

  const CorporationMaturityUpdateFailureState({required this.message});
}