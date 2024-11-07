import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/city.dart';
import '../../../data/models/district.dart';
import '../../../data/repository/district_repository.dart';

part 'district_event.dart';
part 'district_state.dart';

/// Bloc responsible for managing the district.
class DistrictBloc extends Bloc<DistrictEvent, DistrictState> {
  final DistrictRepository _districtRepository;

  DistrictBloc({required DistrictRepository districtRepository})
      : _districtRepository = districtRepository,
        super(const DistrictState()) {
    on<DistrictEvent>((event, emit) {});
    on<DistrictLoadList>(_onLoad);
  }

  FutureOr<void> _onLoad(
      DistrictLoadList event, Emitter<DistrictState> emit) async {
    emit(DistrictInitialState());
    try {
      List<District> district =
          await _districtRepository.getDistrict(event.districtId);
      emit(DistrictLoadSuccessState(districtList: district));
    } catch (e) {
      emit(DistrictLoadFailureState(message: e.toString()));
    }
  }
}
