import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

import '../../../data/models/city.dart';
import '../../../data/repository/city_repository.dart';

part 'city_event.dart';
part 'city_state.dart';

/// Bloc responsible for managing the city.
class CityBloc extends Bloc<CityEvent, CityState> {
  static final _log = AppLogger.getLogger("CityBloc");
  final CityRepository _repository;

  CityBloc({required CityRepository repository}) : _repository = repository, super(const CityInitialState()) {
    on<CityEvent>((event, emit) {});
    on<CityLoad>(_onLoad);
  }

  FutureOr<void> _onLoad(CityLoad event, Emitter<CityState> emit) async {
    _log.debug("BEGIN: getCity bloc: _onLoad");
    emit(const CityLoadingState());
    try {
      List<City?> cities = await _repository.list();
      emit(CityLoadSuccessState(cities: cities));
      _log.debug("END: getCity bloc: _onLoad success: {}", [cities.toString()]);
    } catch (e) {
      emit(CityLoadFailureState(message: e.toString()));
      _log.error("END: getCity bloc: _onLoad error: {}", [e.toString()]);
    }
  }
}
