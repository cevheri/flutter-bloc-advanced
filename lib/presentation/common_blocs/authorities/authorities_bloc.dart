import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repository/authorities_repository.dart';

part 'authorities_event.dart';
part 'authorities_state.dart';

/// Bloc responsible for managing the authorities.
/// It is used to load, update and delete the authorities.
class AuthoritiesBloc extends Bloc<AuthoritiesEvent, AuthoritiesState> {
  final AuthoritiesRepository _authoritiesRepository;

  AuthoritiesBloc({required AuthoritiesRepository authoritiesRepository})
      : _authoritiesRepository = authoritiesRepository,
        super(const AuthoritiesState()) {
    on<AuthoritiesEvent>((event, emit) {});
    on<AuthoritiesLoad>(_onLoad);
  }

  /// Load the current authorities.
  FutureOr<void> _onLoad(
      AuthoritiesLoad event, Emitter<AuthoritiesState> emit) async {
    emit(AuthoritiesInitialState());
    try {
      List role = await _authoritiesRepository.getAuthorities();
      emit(AuthoritiesLoadSuccessState(roleList: role));
    } catch (e) {
      emit(AuthoritiesLoadFailureState(message: e.toString()));
    }
  }
}
