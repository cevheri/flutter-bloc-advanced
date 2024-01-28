part of 'sales_people_bloc.dart';

/// SalesPerson status used the success or failure of the authorities loading.
enum SalesPersonStatus { initial, loading, success, failure }

/// SalesPerson state that contains the current authorities and the status of the authorities.
/// The status is used to display the loading indicator.
///
/// The state is immutable and copyWith is used to update the state.
class SalesPersonState extends Equatable {
  final List<SalesPerson>? salesPerson;
  final SalesPersonStatus status;

  const SalesPersonState({
    this.salesPerson,
    this.status = SalesPersonStatus.initial,
  });

  SalesPersonState copyWith({
    List<SalesPerson>? authorities,
    SalesPersonStatus? status,
  }) {
    return SalesPersonState(
      status: status ?? this.status,
        salesPerson: authorities ?? this.salesPerson
    );
  }

  @override
  List<Object> get props => [status];

  @override
  bool get stringify => true;
}

class SalesPersonDefaultState extends SalesPersonState {}
class SalesPersonInitialState extends SalesPersonState {}
class SalesPersonLoadInProgressState extends SalesPersonState {}
class SalesPersonLoadSuccessState extends SalesPersonState {
  final List<SalesPerson> salesPerson;

  const SalesPersonLoadSuccessState({required this.salesPerson});

  @override
  List<Object> get props => [salesPerson];
}
class SalesPersonLoadFailureState extends SalesPersonState {
  final String message;

  const SalesPersonLoadFailureState({required this.message});
}
class SalesPersonEditAuthorityState extends SalesPersonState {
  final SalesPerson getSalesPerson;
  final List<SalesPerson> salesPersonList;

  const SalesPersonEditAuthorityState({required this.getSalesPerson, required this.salesPersonList});
}

