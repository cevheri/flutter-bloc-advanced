import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/station.dart';
import '../../../../data/repository/station_repository.dart';

part 'station_event.dart';

part 'station_state.dart';

/// Bloc responsible for managing the Stations.
class StationBloc extends Bloc<StationEvent, StationState> {
  StationBloc({
    required StationRepository stationRepository,
  })  : _stationRepository = stationRepository,
        super(StationState()) {
    on<StationEvent>((event, emit) {});
    on<StationCreate>(_onCreate);
    on<StationSearch>(_onList);
    on<StationListWithCorporation>(_onListWithCorporation);
    on<StationUpdate>(_onUpdate);
  }

  final StationRepository _stationRepository;

  FutureOr<void> _onCreate(
      StationCreate event, Emitter<StationState> emit) async {
    emit(StationCreateInitialState());
    try {
      var station = await _stationRepository.createStation(event.station);
      emit(StationCreateSuccessState(station: station!));
    } catch (e) {
      emit(StationCreateFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onList(
      StationSearch event, Emitter<StationState> emit) async {
    emit(StationListInitialState());
    try {
      ///TODO: cityId and corporationId should be removed
      var stationList = await _stationRepository.listStation(
        event.cityId ?? "-",
        event.corporationId ?? "-",
      );
      emit(StationListSuccessState(stationList: stationList));
    } catch (e) {
      emit(StationListFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onUpdate(
      StationUpdate event, Emitter<StationState> emit) async {
    emit(StationUpdateInitialState());
    try {
      var station = await _stationRepository.updateStation(event.station);
      emit(StationUpdateSuccessState(station: station!));
    } catch (e) {
      emit(StationUpdateFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onListWithCorporation(
      StationListWithCorporation event, Emitter<StationState> emit) async {
    emit(StationListWithCorporationInitialState());
    try {
      var stationList = await _stationRepository.listStationWithCorporationId(
        event.corporationId,
      );
      emit(StationListWithCorporationSuccessState(stationList: stationList));
    } catch (e) {
      emit(StationListWithCorporationFailureState(message: e.toString()));
    }
  }
}
