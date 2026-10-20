import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/list_authorities_usecase.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

part 'authority_event.dart';
part 'authority_state.dart';

class AuthorityBloc extends Bloc<AuthorityEvent, AuthorityState> {
  AuthorityBloc({required this._listAuthoritiesUseCase}) : super(const AuthorityInitialState()) {
    on<AuthorityLoad>(_onLoad, transformer: EventTransformers.restart());
    on<AuthorityReset>(_onReset);
  }

  static final _log = AppLogger.getLogger('AuthorityBloc');
  final ListAuthoritiesUseCase _listAuthoritiesUseCase;

  /// How many times the authorities were reset. A load drops its result when this changed while its request was out,
  /// so authorities loaded for a session that has ended do not come back.
  int _resets = 0;

  FutureOr<void> _onLoad(AuthorityLoad event, Emitter<AuthorityState> emit) async {
    _log.debug('BEGIN: getAuthorities bloc: _onLoad');
    final resets = _resets;
    emit(const AuthorityLoadingState());
    final result = await _listAuthoritiesUseCase();
    if (resets != _resets) {
      _log.debug('END: getAuthorities bloc: _onLoad result dropped, the authorities were reset meanwhile');
      return;
    }
    switch (result) {
      case Success(:final data):
        emit(AuthorityLoadSuccessState(authorities: data));
        _log.debug('END: getAuthorities bloc: _onLoad success: {}', [data.toString()]);
      case Failure(:final error):
        emit(AuthorityLoadFailureState(message: error.message));
        _log.error('END: getAuthorities bloc: _onLoad error: {}', [error.message]);
    }
  }

  void _onReset(AuthorityReset event, Emitter<AuthorityState> emit) {
    _resets++;
    emit(const AuthorityInitialState());
  }
}
