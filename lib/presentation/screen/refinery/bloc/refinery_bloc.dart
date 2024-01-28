import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/refinery.dart';
import '../../../../data/repository/refinery_repository.dart';

part 'refinery_event.dart';

part 'refinery_state.dart';

class RefineryBloc extends Bloc<RefineryEvent, RefineryState> {
  RefineryBloc({
    required RefineryRepository refineryRepository,
  })  : _refineryRepository = refineryRepository,
        super(RefineryState()) {
    on<RefineryEvent>((event, emit) {});
    on<RefineryCreate>(_onCreate);
    on<RefinerySearch>(_onSearch);
    on<RefineryUpdate>(_onEdit);
  }

  final RefineryRepository _refineryRepository;

  FutureOr<void> _onCreate(
      RefineryCreate event, Emitter<RefineryState> emit) async {
    emit(RefineryInitialState());
    try {
      var refinery = await _refineryRepository.createRefinery(event.refinery);
      emit(RefineryCreateSuccessState(refinery: refinery!));
    } catch (e) {
      emit(RefineryCreateFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onSearch(
      RefinerySearch event, Emitter<RefineryState> emit) async {
    emit(RefineryFindInitialState());
    try {
      List<Refinery> refinery = await _refineryRepository.findRefineryByName();
      emit(RefinerySearchSuccessState(refineryList: refinery));
    } catch (e) {
      emit(RefinerySearchFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onEdit(
      RefineryUpdate event, Emitter<RefineryState> emit) async {
    emit(RefineryUpdateInitialState());
    try {
      var refinery = await _refineryRepository.updateRefinery(event.refinery);
      emit(RefineryUpdateSuccessState(refinery: refinery!));
    } catch (e) {
      emit(RefineryUpdateFailureState(message: e.toString()));
    }
  }
}
