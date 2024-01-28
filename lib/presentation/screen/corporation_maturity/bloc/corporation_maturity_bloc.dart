import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/maturity.dart';
import '../../../../data/models/corporation_maturity.dart';
import '../../../../data/repository/corporation_maturity_repository.dart';
import '../const.dart';

part 'corporation_maturity_event.dart';

part 'corporation_maturity_state.dart';

/// Bloc responsible for managing the CorporationMaturity's.
class CorporationMaturityBloc
    extends Bloc<CorporationMaturityEvent, CorporationMaturityState> {
  CorporationMaturityBloc({
    required CorporationMaturityRepository corporationMaturityRepository,
  })  : _corporationMaturityRepository = corporationMaturityRepository,
        super(CorporationMaturityState()) {
    on<CorporationMaturityEvent>((event, emit) {});
    on<CorporationMaturityCreate>(_onCreate);
    on<CorporationMaturityLoad>(_onLoad);
    on<CorporationMaturityDelete>(_onDelete);
    on<CorporationMaturityUpdate>(_onUpdate);
  }

  final CorporationMaturityRepository _corporationMaturityRepository;

  FutureOr<void> _onCreate(
      CorporationMaturityCreate event, Emitter<CorporationMaturityState> emit) async {
    emit(CorporationMaturityCreateInitialState());
    try {
      var corporationMaturity = await _corporationMaturityRepository
          .createCorporationMaturity(event.corporationMaturity);
      emit(
          CorporationMaturityCreateSuccessState(corporationMaturity: corporationMaturity!));
    } catch (e) {
      emit(CorporationMaturityCreateFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onLoad(
      CorporationMaturityLoad event, Emitter<CorporationMaturityState> emit) async {
    emit(CorporationMaturityLoadInProgressState());
    try {
      var corporationMaturity = await _corporationMaturityRepository
          .getCorporationMaturity(event.id.toString());
      maturityRemainderCalc(corporationMaturity);

      emit(CorporationMaturityLoadSuccessState(
          corporationMaturity: corporationMaturity,
          maturity: ConstCorporationMaturity.maturityRemainderList));
    } catch (e) {
      emit(CorporationMaturityLoadFailureState(message: e.toString()));
    }
  }



  FutureOr<void> _onDelete(
      CorporationMaturityDelete event, Emitter<CorporationMaturityState> emit) async {
    emit(CorporationMaturityDeleteInProgressState());
    try {
      var corporationMaturity = await _corporationMaturityRepository
          .deleteCorporationMaturity(event.id.toString());
      emit(
          CorporationMaturityDeleteSuccessState(corporationMaturity: corporationMaturity!));
    } catch (e) {
      emit(CorporationMaturityDeleteFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onUpdate(
      CorporationMaturityUpdate event, Emitter<CorporationMaturityState> emit) async {
    emit(CorporationMaturityUpdateInProgressState());
    try {
      var corporationMaturity = await _corporationMaturityRepository
          .updateCorporationMaturity(event.corporationMaturity);
      emit(
          CorporationMaturityUpdateSuccessState(corporationMaturity: corporationMaturity!));
    } catch (e) {
      emit(CorporationMaturityUpdateFailureState(message: e.toString()));
    }
  }
}
