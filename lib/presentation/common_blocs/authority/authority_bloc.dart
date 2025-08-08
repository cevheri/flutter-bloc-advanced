import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

import '../../../data/repository/authority_repository.dart';

part 'authority_event.dart';
part 'authority_state.dart';

/// Bloc responsible for managing the authority.
/// It is used to load, update and delete the authority.
class AuthorityBloc extends Bloc<AuthorityEvent, AuthorityState> {
  static final _log = AppLogger.getLogger("AuthorityBloc");
  final AuthorityRepository _repository;

  AuthorityBloc({required AuthorityRepository repository})
    : _repository = repository,
      super(const AuthorityInitialState()) {
    on<AuthorityEvent>((event, emit) {});
    on<AuthorityLoad>(_onLoad);
  }

  /// Load the current authority.
  FutureOr<void> _onLoad(AuthorityLoad event, Emitter<AuthorityState> emit) async {
    _log.debug("BEGIN: getAuthorities bloc: _onLoad");
    emit(const AuthorityLoadingState());
    try {
      final authorities = await _repository.list();
      if (authorities.isEmpty) {
        emit(const AuthorityLoadFailureState(message: "No authorities found"));
        _log.error("END: getAuthorities bloc: _onLoad error: {}", ["No authorities found"]);
        return;
      }
      emit(AuthorityLoadSuccessState(authorities: authorities));
      _log.debug("END: getAuthorities bloc: _onLoad success: {}", [authorities.toString()]);
    } catch (e) {
      emit(AuthorityLoadFailureState(message: e.toString()));
      _log.error("END: getAuthorities bloc: _onLoad error: {}", [e.toString()]);
    }
  }
}
