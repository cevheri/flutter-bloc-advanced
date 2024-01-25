import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/corporation.dart';
import '../../../../data/repository/corporation_repository.dart';

part 'corporation_event.dart';
part 'corporation_state.dart';

/// Bloc responsible for managing the Corporations.
class CorporationBloc extends Bloc<CorporationEvent, CorporationState> {
  CorporationBloc({
    required CorporationRepository corporationRepository,
  })  : _corporationRepository = corporationRepository,
        super(CorporationState()) {
    on<CorporationEvent>((event, emit) {});
    on<CorporationCreate>(_onCreate);
    on<CorporationSearch>(_onList);
    on<CorporationUpdate>(_onEdit);
  }

  final CorporationRepository _corporationRepository;

  FutureOr<void> _onCreate(CorporationCreate event, Emitter<CorporationState> emit) async {
    emit(CorporationCreateInitialState());
    try {
      var corporation = await _corporationRepository.createCorporation(event.corporation);
      emit(CorporationCreateSuccessState(corporation: corporation!));
    } catch (e) {
      emit(CorporationCreateFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onList(CorporationSearch event, Emitter<CorporationState> emit) async {
    emit(CorporationListInitialState());
    try {
        List<Corporation> corporation = await _corporationRepository.list();
        emit(CorporationListSuccessState(corporationList: corporation));
    } catch (e) {
      emit(CorporationListFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onEdit(CorporationUpdate event, Emitter<CorporationState> emit) async {
    emit(CorporationUpdateInitialState());
    try {
      var corporation = await _corporationRepository.updateCorporation(event.corporation);
      emit(CorporationUpdateSuccessState(corporation: corporation!));
    } catch (e) {
      emit(CorporationUpdateFailureState(message: e.toString()));
    }
  }
}
