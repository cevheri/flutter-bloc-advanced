import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/delete_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/fetch_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/save_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/search_users_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({
    required SearchUsersUseCase searchUsersUseCase,
    required FetchUserUseCase fetchUserUseCase,
    required SaveUserUseCase saveUserUseCase,
    required DeleteUserUseCase deleteUserUseCase,
  }) : _searchUsersUseCase = searchUsersUseCase,
       _fetchUserUseCase = fetchUserUseCase,
       _saveUserUseCase = saveUserUseCase,
       _deleteUserUseCase = deleteUserUseCase,
       super(const UserInitial()) {
    on<UserSearchEvent>(_onSearch);
    on<UserFetchEvent>(_onFetchUser);
    on<UserDeleteEvent>(_onDelete);
    on<UserEditorInit>(_onEditorInit);
    on<UserSubmitEvent>(_onSubmit);
    on<UserViewCompleteEvent>(_onViewComplete);
    on<UserSaveCompleteEvent>(_onSaveComplete);
  }

  static final _log = AppLogger.getLogger('UserBloc');

  final SearchUsersUseCase _searchUsersUseCase;
  final FetchUserUseCase _fetchUserUseCase;
  final SaveUserUseCase _saveUserUseCase;
  final DeleteUserUseCase _deleteUserUseCase;

  /// Lift the carried [UserEntity] forward from any state that holds one.
  /// Used by `_onSaveComplete` / `_onViewComplete` whose only job is to
  /// flip the status without dropping the user being edited.
  UserEntity? _carriedUser() => switch (state) {
    UserFetchSuccess(:final data) => data,
    UserSaveSuccess(:final data) => data,
    UserViewSuccess(:final data) => data,
    _ => null,
  };

  FutureOr<void> _onEditorInit(UserEditorInit event, Emitter<UserState> emit) async {
    _log.debug('BEGIN: onEditorInit UserEditorInit event: {}', []);
    emit(const UserInitial());
    _log.debug('END:onEditorInit UserEditorInit event success: {}', []);
  }

  FutureOr<void> _onSubmit(UserSubmitEvent event, Emitter<UserState> emit) async {
    _log.debug('BEGIN: onSubmit UserSubmitEvent event: {}', [event.user.toString()]);
    emit(UserLoading(data: _carriedUser()));
    final result = await _saveUserUseCase(event.user);
    switch (result) {
      case Success(:final data):
        emit(UserSaveSuccess(data: data));
        _log.debug('END:onSubmit UserSubmitEvent event success: {}', [data.toString()]);
      case Failure(:final error):
        emit(UserFailure(error: error.message));
        _log.error('END:onSubmit UserSubmitEvent event error: {}', [error.message]);
    }
  }

  FutureOr<void> _onDelete(UserDeleteEvent event, Emitter<UserState> emit) async {
    _log.debug('BEGIN: onDelete UserDelete event: {}', [event.id]);
    emit(const UserLoading());
    final result = await _deleteUserUseCase(event.id);
    switch (result) {
      case Success():
        emit(const UserDeleteSuccess());
        _log.debug('END:onDelete UserDelete event success: {}', [event.id]);
      case Failure(:final error):
        emit(UserFailure(error: error.message));
        _log.error('END:onDelete UserDelete event error: {}', [error.message]);
    }
  }

  FutureOr<void> _onFetchUser(UserFetchEvent event, Emitter<UserState> emit) async {
    _log.debug('BEGIN: onFetchUser FetchUserEvent event: {}', [event.id]);
    emit(const UserLoading());
    final result = await _fetchUserUseCase(event.id);
    switch (result) {
      case Success(:final data):
        emit(UserFetchSuccess(data: data));
        _log.debug('END:onFetchUser FetchUserEvent event success: {}', [data.toString()]);
      case Failure(:final error):
        emit(UserFailure(error: error.message));
        _log.error('END:onFetchUser FetchUserEvent event error: {}', [error.message]);
    }
  }

  FutureOr<void> _onSearch(UserSearchEvent event, Emitter<UserState> emit) async {
    _log.debug('BEGIN: onSearch UserSearch event. name:{} authority: {}', [event.name, event.authorities]);
    emit(const UserLoading());
    final result = await _searchUsersUseCase(
      SearchUsersParams(page: event.page, size: event.size, name: event.name, authorities: event.authorities),
    );
    switch (result) {
      case Success(:final data):
        emit(UserSearchSuccess(userList: data));
        _log.debug('END:onSearch UserSearch event success - content count: {}', [data.length]);
      case Failure(:final error):
        emit(UserFailure(error: error.message));
        _log.error('END:onSearch UserSearch event error: {}', [error.message]);
    }
  }

  FutureOr<void> _onSaveComplete(UserSaveCompleteEvent event, Emitter<UserState> emit) async {
    _log.debug('BEGIN: onSaveComplete UserSaveCompleteEvent event: {}', []);
    emit(UserSaveSuccess(data: _carriedUser()));
    _log.debug('END:onSaveComplete UserSaveCompleteEvent event success: {}', []);
  }

  FutureOr<void> _onViewComplete(UserViewCompleteEvent event, Emitter<UserState> emit) async {
    _log.debug('BEGIN: onViewComplete UserViewCompleteEvent event: {}', []);
    emit(UserViewSuccess(data: _carriedUser()));
    _log.debug('END:onViewComplete UserViewCompleteEvent event success: {}', []);
  }
}
