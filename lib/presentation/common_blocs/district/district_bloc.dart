import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

import '../../../data/models/district.dart';
import '../../../data/repository/district_repository.dart';

part 'district_event.dart';
part 'district_state.dart';

/// Bloc responsible for managing the district.
class DistrictBloc extends Bloc<DistrictEvent, DistrictState> {
  static final _log = AppLogger.getLogger("DistrictBloc");
  final DistrictRepository _repository;

  DistrictBloc({required DistrictRepository repository})
    : _repository = repository,
      super(const DistrictInitialState()) {
    on<DistrictEvent>((event, emit) {});
    on<DistrictLoad>(_onLoad);
    on<DistrictLoadByCity>(_onLoadByCity);
  }

  FutureOr<void> _onLoad(DistrictLoad event, Emitter<DistrictState> emit) async {
    _log.debug("BEGIN: getDistrict bloc: _onLoad");
    emit(const DistrictLoadingState());
    try {
      List<District?>? district = await _repository.list();
      emit(DistrictLoadSuccessState(districts: district));
      _log.debug("END: getDistrict bloc: _onLoad success: {}", [district.toString()]);
    } catch (e) {
      emit(DistrictLoadFailureState(message: e.toString()));
      _log.error("END: getDistrict bloc: _onLoad error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _onLoadByCity(DistrictLoadByCity event, Emitter<DistrictState> emit) async {
    _log.debug("BEGIN: getDistrict bloc: _onLoadByCity");
    emit(const DistrictLoadingState());
    try {
      List<District?>? district = await _repository.listByCity(event.cityId);
      emit(DistrictLoadSuccessState(districts: district));
      _log.debug("END: getDistrict bloc: _onLoadByCity success: {}", [district.toString()]);
    } catch (e) {
      emit(DistrictLoadFailureState(message: e.toString()));
      _log.error("END: getDistrict bloc: _onLoadByCity error: {}", [e.toString()]);
    }
  }
}
