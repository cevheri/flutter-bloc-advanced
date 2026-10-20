import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/fetch_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/save_user_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

part 'user_editor_event.dart';
part 'user_editor_state.dart';

/// Bloc for the user *editor* surface — create / edit / view of a
/// single user. Split out of the original `UserBloc` god-bloc (#75).
///
/// Delete is intentionally NOT here; it belongs to `UserListBloc`
/// because that's where the action is invoked and where the
/// post-delete refresh needs to happen.
class UserEditorBloc extends Bloc<UserEditorEvent, UserEditorState> {
  UserEditorBloc({required this._fetchUserUseCase, required this._saveUserUseCase}) : super(const UserEditorInitial()) {
    on<UserEditorReset>(_onReset);
    on<UserEditorFetch>(_onFetch, transformer: EventTransformers.restart());
    on<UserEditorSubmit>(_onSubmit, transformer: EventTransformers.dropConcurrent());
    on<UserEditorViewComplete>(_onViewComplete);
    on<UserEditorSaveComplete>(_onSaveComplete);
  }

  static final _log = AppLogger.getLogger('UserEditorBloc');

  final FetchUserUseCase _fetchUserUseCase;
  final SaveUserUseCase _saveUserUseCase;

  /// Lift the carried [UserEntity] forward from any state that holds
  /// one. Used by `_onSubmit`, `_onSaveComplete` and `_onViewComplete`,
  /// which change the state without dropping the user being edited.
  UserEntity? _carriedUser() => switch (state) {
    UserEditorLoaded(:final data) => data,
    UserEditorSaved(:final data) || UserEditorViewed(:final data) || UserEditorSaveFailure(:final data) => data,
    UserEditorInitial() || UserEditorLoading() || UserEditorFetchFailure() => null,
  };

  FutureOr<void> _onReset(UserEditorReset event, Emitter<UserEditorState> emit) {
    _log.debug('BEGIN: onReset', []);
    emit(const UserEditorInitial());
  }

  FutureOr<void> _onFetch(UserEditorFetch event, Emitter<UserEditorState> emit) async {
    _log.debug('BEGIN: onFetch id: {}', [event.id]);
    emit(const UserEditorLoading());
    final result = await _fetchUserUseCase(event.id);
    switch (result) {
      case Success(:final data):
        emit(UserEditorLoaded(data: data));
        _log.debug('END:onFetch success: {}', [data]);
      case Failure(:final error):
        emit(UserEditorFetchFailure(errorCode: AppErrorCode.fromKey(error.code) ?? AppErrorCode.generic));
        _log.error('END:onFetch error: {}', [error]);
    }
  }

  FutureOr<void> _onSubmit(UserEditorSubmit event, Emitter<UserEditorState> emit) async {
    _log.debug('BEGIN: onSubmit user: {}', [event.user]);
    final carried = _carriedUser();
    emit(UserEditorLoading(data: carried));
    final result = await _saveUserUseCase(event.user);
    switch (result) {
      case Success(:final data):
        emit(UserEditorSaved(data: data));
        _log.debug('END:onSubmit success: {}', [data]);
      case Failure(:final error):
        emit(UserEditorSaveFailure(data: carried));
        _log.error('END:onSubmit error: {}', [error]);
    }
  }

  FutureOr<void> _onSaveComplete(UserEditorSaveComplete event, Emitter<UserEditorState> emit) {
    emit(UserEditorSaved(data: _carriedUser()));
  }

  FutureOr<void> _onViewComplete(UserEditorViewComplete event, Emitter<UserEditorState> emit) {
    emit(UserEditorViewed(data: _carriedUser()));
  }
}
