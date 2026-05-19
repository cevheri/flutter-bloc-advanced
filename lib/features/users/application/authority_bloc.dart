import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/list_authorities_usecase.dart';

part 'authority_event.dart';
part 'authority_state.dart';

class AuthorityBloc extends Bloc<AuthorityEvent, AuthorityState> {
  AuthorityBloc({required ListAuthoritiesUseCase listAuthoritiesUseCase})
    : _listAuthoritiesUseCase = listAuthoritiesUseCase,
      super(const AuthorityInitialState()) {
    on<AuthorityLoad>(_onLoad);
  }

  static final _log = AppLogger.getLogger('AuthorityBloc');
  final ListAuthoritiesUseCase _listAuthoritiesUseCase;

  FutureOr<void> _onLoad(AuthorityLoad event, Emitter<AuthorityState> emit) async {
    _log.debug('BEGIN: getAuthorities bloc: _onLoad');
    emit(const AuthorityLoadingState());
    final result = await _listAuthoritiesUseCase();
    switch (result) {
      case Success(:final data):
        emit(AuthorityLoadSuccessState(authorities: data));
        _log.debug('END: getAuthorities bloc: _onLoad success: {}', [data.toString()]);
      case Failure(:final error):
        emit(AuthorityLoadFailureState(message: error.message));
        _log.error('END: getAuthorities bloc: _onLoad error: {}', [error.message]);
    }
  }
}
