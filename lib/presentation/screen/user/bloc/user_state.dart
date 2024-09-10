part of 'user_bloc.dart';

enum UserStatus { initial, loading, success, failure }

class UserState {
  final User? user;
  final UserStatus status;

  const UserState({
    this.user,
    this.status = UserStatus.initial,
  });

  UserState copyWith({
    User? user,
    UserStatus? status,
  }) {
    return UserState(status: status ?? this.status, user: user ?? this.user);
  }
}

class UserInitialState extends UserState {}

class UserEditInitialState extends UserState {}

class UserFindInitialState extends UserState {}

class UserLoadInProgressState extends UserState {}

class UserLoadSuccessState extends UserState {
  final User user;

  const UserLoadSuccessState({required this.user});
}

class UserEditSuccessState extends UserState {
  final User user;

  const UserEditSuccessState({required this.user});
}

class UserSearchSuccessState extends UserState {
  final List<User> userList;

  const UserSearchSuccessState({required this.userList});
}

class UserLoadFailureState extends UserState {
  final String message;

  const UserLoadFailureState({required this.message});
}

class UserEditFailureState extends UserState {
  final String message;

  const UserEditFailureState({required this.message});
}

class UserSearchFailureState extends UserState {
  final String message;

  const UserSearchFailureState({required this.message});
}

class UserListInitialState extends UserState {}

class UserListSuccessState extends UserState {
  final List<User> userList;

  const UserListSuccessState({required this.userList});
}

class UserListFailureState extends UserState {
  final String message;

  const UserListFailureState({required this.message});
}
