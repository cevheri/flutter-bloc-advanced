import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/user.dart';
import '../../../../data/repository/user_repository.dart';

part 'user_event.dart';
part 'user_state.dart';

/// Bloc responsible for managing the Users.
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({
    required UserRepository userRepository,
  })  : _userRepository = userRepository,
        super(const UserState()) {
    on<UserEvent>((event, emit) {});
    on<UserCreate>(_onCreate);
    on<UserSearch>(_onSearch);
    on<UserEdit>(_onEdit);
    on<UserList>(_onList);
  }

  final UserRepository _userRepository;

  FutureOr<void> _onCreate(UserCreate event, Emitter<UserState> emit) async {
    emit(UserInitialState());
    try {
      var user = await _userRepository.createUser(event.user);
      emit(UserLoadSuccessState(userLoadSuccess: user!));
    } catch (e) {
      emit(UserLoadFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onSearch(UserSearch event, Emitter<UserState> emit) async {
    emit(UserFindInitialState());
    try {
      if (event.name == "") {
        List<User> user = await _userRepository.findUserByAuthority(event.rangeStart, event.rangeEnd, event.authority);
        emit(UserSearchSuccessState(userList: user));
      }
      if (event.name != "") {
        List<User> user = await _userRepository.findUserByName(event.rangeStart, event.rangeEnd, event.name, event.authority);
        emit(UserSearchSuccessState(userList: user));
      }
    } catch (e) {
      emit(UserSearchFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onList(UserList event, Emitter<UserState> emit) async {
    emit(UserListInitialState());
    try {
      List<User> user = await _userRepository.listUser(0, 100);
      emit(UserListSuccessState(userList: user));
    } catch (e) {
      emit(UserListFailureState(message: e.toString()));
    }
  }

  FutureOr<void> _onEdit(UserEdit event, Emitter<UserState> emit) async {
    emit(UserEditInitialState());
    try {
      var user = await _userRepository.updateUser(event.user);
      emit(UserEditSuccessState(userEditSuccess: user!));
    } catch (e) {
      emit(UserEditFailureState(message: e.toString()));
    }
  }
}
