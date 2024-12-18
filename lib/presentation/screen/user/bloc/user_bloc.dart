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

  UserBloc({
    required UserRepository repository,
  })  : _repository = repository,
        super(const UserState()) {
    on<UserEvent>((event, emit) {});
    // on<UserCreate>(_onCreate);
    on<UserSearch>(_onSearch);
    // on<UserEditEvent>(_onEdit);
    on<UserList>(_onList);
    on<UserFetchEvent>(_onFetchUser);
    on<UserDeleteEvent>(_onDelete);
    on<UserEditorInit>(_onEditorInit);
    on<UserSubmitEvent>(_onSubmit);
  }

  /// Initialize the UserEditor.
  FutureOr<void> _onEditorInit(UserEditorInit event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onEditorInit UserEditorInit event: {}", []);
    emit(const UserInitialState());
    _log.debug("END:onEditorInit UserEditorInit event success: {}", []);
  }
  
  /// Submit an entity in the EditorForm
  FutureOr<void> _onSubmit(UserSubmitEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onSubmit UserSubmitEvent event: {}", [event.user.toString()]);
    emit(state.copyWith(status: UserStatus.loading));
    try {
      final user = event.user.id == null ? await _repository.create(event.user) : await _repository.update(event.user);
      emit(state.copyWith(status: UserStatus.success, data: user));
      _log.debug("END:onSubmit UserSubmitEvent event success: {}", [user.toString()]);
    } catch (e) {
      emit(state.copyWith(status: UserStatus.failure));
      _log.error("END:onSubmit UserSubmitEvent event error: {}", [e.toString()]);
    }
  }
  

  /// Retrieve a user by id.
  FutureOr<void> _onFetchUser(UserFetchEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onFetchUser FetchUserEvent event: {}", [event.id]);
    emit(const UserLoadInProgressState());
    try {
      var user = await _repository.getUser(event.id);
      emit(UserLoadSuccessState(userLoadSuccess: user!));
      _log.debug("END:onFetchUser FetchUserEvent event success: {}", [user.toString()]);
    } catch (e) {
      emit(UserLoadFailureState(message: e.toString()));
      _log.error("END:onFetchUser FetchUserEvent event error: {}", [e.toString()]);
    }
  }

  // /// Create a new user.
  // FutureOr<void> _onCreate(UserCreate event, Emitter<UserState> emit) async {
  //   _log.debug("BEGIN: onCreate UserCreate event: {}", [event.user.toString()]);
  //   emit(const UserInitialState());
  //   try {
  //     var user = await _repository.create(event.user);
  //     emit(UserLoadSuccessState(userLoadSuccess: user!));
  //     _log.debug("END:onCreate UserCreate event success: {}", [user.toString()]);
  //   } catch (e) {
  //     emit(UserLoadFailureState(message: e.toString()));
  //     _log.error("END:onCreate UserCreate event error: {}", [e.toString()]);
  //   }
  // }

  /// Search a user by name or authority.
  FutureOr<void> _onSearch(UserSearch event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onSearch UserSearch event: {}", [event.name]);
    emit(const UserFindInitialState());
    try {
      if (event.name == "") {
        List<User> user = await _repository.findUserByAuthority(event.rangeStart, event.rangeEnd, event.authority);
        emit(UserSearchSuccessState(userList: user));
        _log.debug("END:onSearch UserSearch event without name success: {}", [user.toString()]);
      }
      if (event.name != "") {
        List<User> user = await _repository.findUserByName(event.rangeStart, event.rangeEnd, event.name, event.authority);
        emit(UserSearchSuccessState(userList: user));
        _log.debug("END:onSearch UserSearch event with name success: {}", [user.toString()]);
      }
    } catch (e) {
      emit(UserSearchFailureState(message: e.toString()));
      _log.error("END:onSearch UserSearch event error: {}", [e.toString()]);
    }
  }

  /// List all users.
  FutureOr<void> _onList(UserList event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onList UserList event: {}", []);
    emit(const UserListInitialState());
    try {
      List<User> user = await _repository.listUser(0, 100);
      emit(UserListSuccessState(userList: user));
      _log.debug("END:onList UserList event success: {}", [user.toString()]);
    } catch (e) {
      emit(UserListFailureState(message: e.toString()));
      _log.error("END:onList UserList event error: {}", [e.toString()]);
    }
  }

  // /// Update a user.
  // FutureOr<void> _onEdit(UserEditEvent event, Emitter<UserState> emit) async {
  //   _log.debug("BEGIN: onEdit UserEdit event: {}", [event.user.toString()]);
  //   emit(const UserEditInitialState());
  //   try {
  //     var user = await _repository.update(event.user);
  //     emit(UserEditSuccessState(userEditSuccess: user!));
  //     _log.debug("END:onEdit UserEdit event success: {}", [user.toString()]);
  //   } catch (e) {
  //     emit(UserEditFailureState(message: e.toString()));
  //     _log.error("END:onEdit UserEdit event error: {}", [e.toString()]);
  //   }
  // }

  /// Delete a user.
  FutureOr<void> _onDelete(UserDeleteEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onDelete UserDelete event: {}", [event.id]);
    emit(const UserDeleteLoadingState());
    try {
      if(event.id == "user-1") {
        emit(const UserDeleteFailureState(message: "Admin user cannot be deleted"));
        _log.error("END:onDelete UserDelete event error: {}", ["Admin user cannot be deleted"]);
      }
      await _repository.deleteUser(event.id);
      emit(const UserDeleteSuccessState());
      _log.debug("END:onDelete UserDelete event success: {}", [event.id]);
    } catch (e) {
      emit(UserDeleteFailureState(message: e.toString()));
      _log.error("END:onDelete UserDelete event error: {}", [e.toString()]);
    }
  }
}
