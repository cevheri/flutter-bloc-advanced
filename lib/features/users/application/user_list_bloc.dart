import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/delete_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/search_users_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

part 'user_list_event.dart';
part 'user_list_state.dart';

/// Bloc for the user *list* surface — searching/filtering the catalog
/// and deleting rows from it.
///
/// Split out of the original [UserBloc] god-bloc (#75). Delete lives
/// here (not in [UserEditorBloc]) because the action is invoked from
/// the list rows and the list is the natural place to refresh after a
/// successful delete.
class UserListBloc extends Bloc<UserListEvent, UserListState> {
  UserListBloc({required SearchUsersUseCase searchUsersUseCase, required DeleteUserUseCase deleteUserUseCase})
    : _searchUsersUseCase = searchUsersUseCase,
      _deleteUserUseCase = deleteUserUseCase,
      super(const UserListInitial()) {
    on<UserListSearch>(_onSearch, transformer: EventTransformers.debounceRestartable());
    on<UserListDelete>(_onDelete, transformer: EventTransformers.dropConcurrent());
  }

  static final _log = AppLogger.getLogger('UserListBloc');

  final SearchUsersUseCase _searchUsersUseCase;
  final DeleteUserUseCase _deleteUserUseCase;

  FutureOr<void> _onSearch(UserListSearch event, Emitter<UserListState> emit) async {
    _log.debug('BEGIN: onSearch name:{} authorities:{}', [event.name, event.authorities]);
    emit(const UserListLoading());
    final result = await _searchUsersUseCase(
      SearchUsersParams(page: event.page, size: event.size, name: event.name, authorities: event.authorities),
    );
    switch (result) {
      case Success(:final data):
        emit(UserListLoaded(users: data));
        _log.debug('END:onSearch success - count: {}', [data.length]);
      case Failure(:final error):
        emit(UserListFailure(error: error.message));
        _log.error('END:onSearch error: {}', [error.message]);
    }
  }

  FutureOr<void> _onDelete(UserListDelete event, Emitter<UserListState> emit) async {
    _log.debug('BEGIN: onDelete id: {}', [event.id]);
    emit(const UserListLoading());
    final result = await _deleteUserUseCase(event.id);
    switch (result) {
      case Success():
        emit(const UserListDeleteSuccess());
        _log.debug('END:onDelete success id: {}', [event.id]);
      case Failure(:final error):
        emit(UserListFailure(error: error.message));
        _log.error('END:onDelete error: {}', [error.message]);
    }
  }
}
