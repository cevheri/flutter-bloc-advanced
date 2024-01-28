import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/sales_person.dart';
import '../../../data/repository/sales_people_repository.dart';

part 'sales_people_event.dart';
part 'sales_people_state.dart';

/// Bloc responsible for managing the salesPerson.
class SalesPersonBloc extends Bloc<SalesPersonEvent, SalesPersonState> {
  final SalesPersonRepository _salesPersonRepository;

  SalesPersonBloc({required SalesPersonRepository salesPersonRepository})
      : _salesPersonRepository = salesPersonRepository,
        super(const SalesPersonState()) {
    on<SalesPersonEvent>((event, emit) {});
    on<SalesPersonLoad>(_onLoad);
    on<SalesPersonLoadDefault>(_onLoadDefault);
    on<SalesPersonEditAuthority>(_onEditAuthority);
  }

  FutureOr<void> _onLoad(
      SalesPersonLoad event, Emitter<SalesPersonState> emit) async {
    emit(SalesPersonInitialState());
    try {
      List<SalesPerson> salesPerson =
          await _salesPersonRepository.getSalesPerson();
      emit(SalesPersonLoadSuccessState(salesPerson: salesPerson));
    } catch (e) {
      emit(SalesPersonLoadFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onLoadDefault(
      SalesPersonLoadDefault event, Emitter<SalesPersonState> emit) async {
    emit(SalesPersonDefaultState());
  }

  FutureOr<void> _onEditAuthority(
      SalesPersonEditAuthority event, Emitter<SalesPersonState> emit) async {
    try {
      List<SalesPerson> salesPerson =
          await _salesPersonRepository.getSalesPerson();
      emit(SalesPersonEditAuthorityState(
          salesPersonList: salesPerson,
          getSalesPerson: event.getSalesPersonId == ""
              ? salesPerson.first
              : salesPerson.firstWhere(
                  (element) => element.id == event.getSalesPersonId)));
    } catch (e) {
      emit(SalesPersonLoadFailureState(message: e.toString()));
    }
  }
}
