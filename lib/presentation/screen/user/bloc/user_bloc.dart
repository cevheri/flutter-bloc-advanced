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
  final UserRepository _userRepository;

  UserBloc({
    required UserRepository userRepository,
  })  : _userRepository = userRepository,
        super(const UserState()) {
    on<UserEvent>((event, emit) {});
    on<UserCreate>(_onCreate);
    on<UserSearch>(_onSearch);
    on<UserEdit>(_onEdit);
    on<UserList>(_onList);
    on<FetchUserEvent>(_onFetchUser);
  }

  FutureOr<void> _onFetchUser(FetchUserEvent event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onFetchUser FetchUserEvent event: {}", [event.id]);
    emit(const UserLoadInProgressState());
    try {
      var user = await _userRepository.getUser(event.id);
      emit(UserLoadSuccessState(userLoadSuccess: user!));
      _log.debug("END:onFetchUser FetchUserEvent event success: {}", [user.toString()]);
    } catch (e) {
      emit(UserLoadFailureState(message: e.toString()));
      _log.error("END:onFetchUser FetchUserEvent event error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _onCreate(UserCreate event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onCreate UserCreate event: {}", [event.user.toString()]);
    emit(const UserInitialState());
    try {
      var user = await _userRepository.createUser(event.user);
      emit(UserLoadSuccessState(userLoadSuccess: user!));
      _log.debug("END:onCreate UserCreate event success: {}", [user.toString()]);
    } catch (e) {
      emit(UserLoadFailureState(message: e.toString()));
      _log.error("END:onCreate UserCreate event error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _onSearch(UserSearch event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onSearch UserSearch event: {}", [event.name]);
    emit(const UserFindInitialState());
    try {
      if (event.name == "") {
        List<User> user = await _userRepository.findUserByAuthority(event.rangeStart, event.rangeEnd, event.authority);
        emit(UserSearchSuccessState(userList: user));
        _log.debug("END:onSearch UserSearch event without name success: {}", [user.toString()]);
      }
      if (event.name != "") {
        List<User> user = await _userRepository.findUserByName(event.rangeStart, event.rangeEnd, event.name, event.authority);
        emit(UserSearchSuccessState(userList: user));
        _log.debug("END:onSearch UserSearch event with name success: {}", [user.toString()]);
      }
    } catch (e) {
      emit(UserSearchFailureState(message: e.toString()));
      _log.error("END:onSearch UserSearch event error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _onList(UserList event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onList UserList event: {}", []);
    emit(const UserListInitialState());
    try {
      List<User> user = await _userRepository.listUser(0, 100);
      emit(UserListSuccessState(userList: user));
      _log.debug("END:onList UserList event success: {}", [user.toString()]);
    } catch (e) {
      emit(UserListFailureState(message: e.toString()));
      _log.error("END:onList UserList event error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _onEdit(UserEdit event, Emitter<UserState> emit) async {
    _log.debug("BEGIN: onEdit UserEdit event: {}", [event.user.toString()]);
    emit(const UserEditInitialState());
    try {
      var user = await _userRepository.updateUser(event.user);
      emit(UserEditSuccessState(userEditSuccess: user!));
      _log.debug("END:onEdit UserEdit event success: {}", [user.toString()]);
    } catch (e) {
      emit(UserEditFailureState(message: e.toString()));
      _log.error("END:onEdit UserEdit event error: {}", [e.toString()]);
    }
  }
}
