import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/status.dart';
import '../../../data/repository/status_repository.dart';

part 'status_event.dart';
part 'status_state.dart';

/// Bloc responsible for managing the status.
class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final StatusRepository _statusRepository;

  StatusBloc({required StatusRepository statusRepository})
      : _statusRepository = statusRepository,
        super(const StatusState()) {
    on<StatusEvent>((event, emit) {});
    on<StatusLoadList>(_onList);
    on<StatusListWithOffer>(_onListWithOffer);
  }

  FutureOr<void> _onList(StatusLoadList event, Emitter<StatusState> emit) async {
    emit(StatusInitialState());
    try {
      List<Status> status = await _statusRepository.listStatus();

      emit(StatusLoadSuccessState(statusLoaded: status));
    } catch (e) {
      emit(StatusLoadFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onListWithOffer(StatusListWithOffer event, Emitter<StatusState> emit) async {
    emit(StatusWithOfferInitialState());
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? role = prefs.getString('role');
    try {
    List<Status> status = await _statusRepository.listStatusWithOffer(event.offerStatusId, role!);
      emit(StatusWithOfferLoadSuccessState(statusList: status));
    } catch (e) {
      emit(StatusWithOfferLoadFailureState(message: e.toString()));
    }
  }
}
