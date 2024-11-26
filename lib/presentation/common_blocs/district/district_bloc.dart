import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/district.dart';
import '../../../data/repository/district_repository.dart';

part 'district_event.dart';
part 'district_state.dart';

/// Bloc responsible for managing the district.
class DistrictBloc extends Bloc<DistrictEvent, DistrictState> {
  final DistrictRepository _districtRepository;

  DistrictBloc({required DistrictRepository districtRepository})
      : _districtRepository = districtRepository,
        super(const DistrictInitialState()) {
    on<DistrictEvent>((event, emit) {});
    on<DistrictLoad>(_onLoad);
    on<DistrictLoadByCity>(_onLoadByCity);
  }

  FutureOr<void> _onLoad(DistrictLoad event, Emitter<DistrictState> emit) async {
    emit(const DistrictLoadingState());
    try {
      List<District?>? district = await _districtRepository.getDistricts();
      emit(DistrictLoadSuccessState(districts: district));
    } catch (e) {
      emit(DistrictLoadFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onLoadByCity(DistrictLoadByCity event, Emitter<DistrictState> emit) async {
    emit(const DistrictLoadingState());
    try {
      List<District?>? district = await _districtRepository.getDistrictsByCity(event.cityId);
      emit(DistrictLoadSuccessState(districts: district));
    } catch (e) {
      emit(DistrictLoadFailureState(message: e.toString()));
    }
  }
}
