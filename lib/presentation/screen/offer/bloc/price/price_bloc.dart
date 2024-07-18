import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'price_event.dart';
part 'price_state.dart';

class PriceBloc extends Bloc<PriceEvent, PriceState> {
  PriceBloc() : super(PriceInitial()) {
    on<PriceEvent>((event, emit) {});
    on<PriceUpdateEvent>(_onUpdate);
  }

  void _onUpdate(PriceUpdateEvent event, Emitter<PriceState> emit) {
    emit(PriceUpdatedInitial());
    emit(PriceUpdatedSuccess(event.price));
    emit(PriceUpdatedFailure('Error'));
  }
}
