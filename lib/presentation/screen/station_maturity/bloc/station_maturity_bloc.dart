import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/maturity.dart';
import '../../../../data/models/station_maturity.dart';
import '../../../../data/repository/station_maturity_repository.dart';
import '../../offer/offer_screen_const.dart';
import '../station_maturity_const.dart';

part 'station_maturity_event.dart';

part 'station_maturity_state.dart';

/// Bloc responsible for managing the StationMaturity's.
class StationMaturityBloc
    extends Bloc<StationMaturityEvent, StationMaturityState> {
  StationMaturityBloc({
    required StationMaturityRepository stationMaturityRepository,
  })  : _stationMaturityRepository = stationMaturityRepository,
        super(StationMaturityState()) {
    on<StationMaturityEvent>((event, emit) {});
    on<StationMaturityCreate>(_onCreate);
    on<StationMaturityLoad>(_onLoad);
    on<StationMaturityDelete>(_onDelete);
    on<StationMaturityUpdate>(_onUpdate);
  }

  final StationMaturityRepository _stationMaturityRepository;

  FutureOr<void> _onCreate(
      StationMaturityCreate event, Emitter<StationMaturityState> emit) async {
    emit(StationMaturityCreateInitialState());
    try {
      var stationMaturity = await _stationMaturityRepository
          .createStationMaturity(event.stationMaturity);
      emit(
          StationMaturityCreateSuccessState(stationMaturity: stationMaturity!));
    } catch (e) {
      emit(StationMaturityCreateFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onLoad(
      StationMaturityLoad event, Emitter<StationMaturityState> emit) async {
    emit(StationMaturityLoadInProgressState());
    try {
      var stationMaturity = await _stationMaturityRepository
          .getStationMaturity(event.id.toString());
      maturityRemainderCalc(stationMaturity);

      ConstOfferStationMaturity.stationMaturityAllList = stationMaturity;

      emit(StationMaturityLoadSuccessState(
          stationMaturity: stationMaturity,
          maturity: ConstStationMaturity.maturityRemainderList));
    } catch (e) {
      emit(StationMaturityLoadFailureState(message: e.toString()));
    }
  }



  FutureOr<void> _onDelete(
      StationMaturityDelete event, Emitter<StationMaturityState> emit) async {
    emit(StationMaturityDeleteInProgressState());
    try {
      var stationMaturity = await _stationMaturityRepository
          .deleteStationMaturity(event.id.toString());
      emit(
          StationMaturityDeleteSuccessState(stationMaturity: stationMaturity!));
    } catch (e) {
      emit(StationMaturityDeleteFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onUpdate(
      StationMaturityUpdate event, Emitter<StationMaturityState> emit) async {
    emit(StationMaturityUpdateInProgressState());
    try {
      var stationMaturity = await _stationMaturityRepository
          .updateStationMaturity(event.stationMaturity);
      emit(
          StationMaturityUpdateSuccessState(stationMaturity: stationMaturity!));
    } catch (e) {
      emit(StationMaturityUpdateFailureState(message: e.toString()));
    }
  }
}
