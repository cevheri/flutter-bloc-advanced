import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

import '../../../../data/models/user.dart';
import '../../../../data/repository/user_repository.dart';

part 'user_event.dart';
part 'user_state.dart';

/// Bloc responsible for managing the Users Business Logic.
class UserBloc extends Bloc<UserEvent, UserState> {
  static final _log = AppLogger.getLogger("UserBloc");
  final UserRepository _repository;

  UserBloc({required UserRepository repository}) : _repository = repository, super(const UserState()) {
    on<UserEvent>((event, emit) {});
    on<UserSearchEvent>(_onSearch);
    on<UserFetchEvent>(_onFetchUser);
    on<UserDeleteEvent>(_onDelete);
    on<UserEditorInit>(_onEditorInit);
    on<UserSubmitEvent>(_onSubmit);
    on<UserViewCompleteEvent>(_onViewComplete);
    on<UserSaveCompleteEvent>(_onSaveComplete);
  }

  /// Initialize the UserEditor.
  FutureOr<void> _onEditorInit(UserEditorInit event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onEditorInit UserEditorInit event: {}", []);
    emit(const UserState());
    _log.debug("END:onEditorInit UserEditorInit event success: {}", []);
  }

  /// Submit an entity in the EditorForm
  FutureOr<void> _onSubmit(UserSubmitEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onSubmit UserSubmitEvent event: {}", [event.user.toString()]);
    emit(state.copyWith(status: UserStatus.loading));
    try {
      final user = event.user.id == null ? await _repository.create(event.user) : await _repository.update(event.user);
      emit(state.copyWith(status: UserStatus.saveSuccess, data: user));
      _log.debug("END:onSubmit UserSubmitEvent event success: {}", [user.toString()]);
    } catch (e) {
      emit(state.copyWith(status: UserStatus.failure));
      _log.error("END:onSubmit UserSubmitEvent event error: {}", [e.toString()]);
    }
  }

  /// Delete a user.
  FutureOr<void> _onDelete(UserDeleteEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onDelete UserDelete event: {}", [event.id]);
    emit(const UserState(status: UserStatus.loading));
    try {
      if (event.id == "user-1") {
        emit(state.copyWith(status: UserStatus.failure, err: "Admin user cannot be deleted"));
        _log.error("END:onDelete UserDelete event error: {}", ["Admin user cannot be deleted"]);
        return;
      }
      await _repository.delete(event.id);
      emit(state.copyWith(status: UserStatus.deleteSuccess));
      _log.debug("END:onDelete UserDelete event success: {}", [event.id]);
    } catch (e) {
      emit(state.copyWith(status: UserStatus.failure, err: e.toString()));
      _log.error("END:onDelete UserDelete event error: {}", [e.toString()]);
    }
  }

  /// Retrieve a user by id.
  FutureOr<void> _onFetchUser(UserFetchEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onFetchUser FetchUserEvent event: {}", [event.id]);
    emit(const UserState(status: UserStatus.loading));
    try {
      final entity = await _repository.retrieve(event.id);
      emit(state.copyWith(status: UserStatus.fetchSuccess, data: entity));
      _log.debug("END:onFetchUser FetchUserEvent event success: {}", [entity.toString()]);
    } catch (e) {
      emit(state.copyWith(status: UserStatus.failure, err: e.toString()));
      _log.error("END:onFetchUser FetchUserEvent event error: {}", [e.toString()]);
    }
  }

  /// Search a user by name or authority.
  FutureOr<void> _onSearch(UserSearchEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onSearch UserSearch event. name:{} authority: {}", [event.name, event.authorities]);
    emit(state.copyWith(status: UserStatus.loading));
    try {
      if ((event.name == null || event.name == "") && (event.authorities == null || event.authorities == "")) {
        final entities = await _repository.list();
        emit(state.copyWith(status: UserStatus.searchSuccess, userList: entities));
        _log.debug("END:onSearch UserSearch event success - list. content count: {}", [entities.length]);
        return;
      } else if (event.name != null &&
          event.name!.isNotEmpty &&
          event.authorities != null &&
          event.authorities!.isNotEmpty) {
        final entities = await _repository.listByNameAndRole(event.page, event.size, event.name!, event.authorities!);
        emit(state.copyWith(status: UserStatus.searchSuccess, userList: entities));
        _log.debug("END:onSearch UserSearch event with name success - name and authority content count: {}", [
          entities.length,
        ]);
        return;
      } else if (event.authorities != null && event.authorities!.isNotEmpty) {
        final entities = await _repository.listByAuthority(event.page, event.size, event.authorities!);
        emit(state.copyWith(status: UserStatus.searchSuccess, userList: entities));
        _log.debug("END:onSearch UserSearch event success authority - content count: {}", [entities.length]);
        return;
      }
    } catch (e) {
      emit(state.copyWith(status: UserStatus.failure, err: e.toString()));
      _log.error("END:onSearch UserSearch event error: {}", [e.toString()]);
    }
  }

  /// save screen completed
  FutureOr<void> _onSaveComplete(UserSaveCompleteEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onSaveComplete UserSaveCompleteEvent event: {}", []);
    emit(state.copyWith(status: UserStatus.saveSuccess));
    _log.debug("END:onSaveComplete UserSaveCompleteEvent event success: {}", []);
  }

  /// View screen completed
  FutureOr<void> _onViewComplete(UserViewCompleteEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onViewComplete UserViewCompleteEvent event: {}", []);
    emit(state.copyWith(status: UserStatus.viewSuccess));
    _log.debug("END:onViewComplete UserViewCompleteEvent event success: {}", []);
  }
}
