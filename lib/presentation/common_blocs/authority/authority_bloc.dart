import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repository/authority_repository.dart';

part 'authority_event.dart';
part 'authority_state.dart';

/// Bloc responsible for managing the authority.
/// It is used to load, update and delete the authority.
class AuthorityBloc extends Bloc<AuthorityEvent, AuthorityState> {
  final AuthorityRepository _authorityRepository;

  AuthorityBloc({required AuthorityRepository authorityRepository})
      : _authorityRepository = authorityRepository,
        super(const AuthorityInitialState()) {
    on<AuthorityEvent>((event, emit) {});
    on<AuthorityLoad>(_onLoad);
  }

  /// Load the current authority.
  FutureOr<void> _onLoad(AuthorityLoad event, Emitter<AuthorityState> emit) async {
    emit(const AuthorityLoadingState());
    try {
      final authorities = await _authorityRepository.getAuthorities();
      emit(AuthorityLoadSuccessState(authorities: authorities));
    } catch (e) {
      emit(AuthorityLoadFailureState(message: e.toString()));
    }
  }
}
