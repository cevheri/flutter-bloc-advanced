import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/city.dart';
import '../../../data/repository/city_repository.dart';

part 'city_event.dart';

part 'city_state.dart';

/// Bloc responsible for managing the city.
class CityBloc extends Bloc<CityEvent, CityState> {
  final CityRepository _cityRepository;

  CityBloc({required CityRepository cityRepository})
      : _cityRepository = cityRepository,
        super(const CityState()) {
    on<CityEvent>((event, emit) {});
    on<CityLoadList>(_onLoad);
  }

  FutureOr<void> _onLoad(CityLoadList event, Emitter<CityState> emit) async {
    emit(CityInitialState());
    try {
      List<City> city = await _cityRepository.getCity();
      emit(CityLoadSuccessState(cityList: city));
    } catch (e) {
      emit(CityLoadFailureState(message: e.toString()));
    }
  }
}
