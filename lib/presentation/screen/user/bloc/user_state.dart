part of 'user_bloc.dart';

enum UserStatus { initial, loading, success, failure }

class UserState extends Equatable {
  final User? data;
  final UserStatus status;

  const UserState({
    this.data,
    this.status = UserStatus.initial,
  });

  UserState copyWith({
    User? data,
    UserStatus? status,
  }) {
    return UserState(status: status ?? this.status, data: data ?? this.data);
  }

  @override
  List<Object?> get props => [data, status];
}

class UserInitialState extends UserState {
  const UserInitialState() : super(status: UserStatus.initial);
}

class UserEditInitialState extends UserState {
  const UserEditInitialState() : super(status: UserStatus.initial);
}

class UserFindInitialState extends UserState {
  const UserFindInitialState() : super(status: UserStatus.initial);
}

class UserLoadInProgressState extends UserState {
  const UserLoadInProgressState() : super(status: UserStatus.loading);
}

class UserLoadSuccessState extends UserState {
  final User userLoadSuccess;

  const UserLoadSuccessState({required this.userLoadSuccess}) : super(data: userLoadSuccess, status: UserStatus.success);
}

class UserEditSuccessState extends UserState {
  final User userEditSuccess;

  const UserEditSuccessState({required this.userEditSuccess}) : super(data: userEditSuccess, status: UserStatus.success);
}

class UserSearchSuccessState extends UserState {
  final List<User> userList;

  const UserSearchSuccessState({required this.userList});
}

class UserLoadFailureState extends UserState {
  final String message;

  const UserLoadFailureState({required this.message}) : super(status: UserStatus.failure);
}

class UserEditFailureState extends UserState {
  final String message;

  const UserEditFailureState({required this.message}) : super(status: UserStatus.failure);
}

class UserSearchFailureState extends UserState {
  final String message;

  const UserSearchFailureState({required this.message}) : super(status: UserStatus.failure);
}

class UserListInitialState extends UserState {
  const UserListInitialState() : super(status: UserStatus.initial);
}

class UserListSuccessState extends UserState {
  final List<User> userList;

  const UserListSuccessState({required this.userList}) : super(status: UserStatus.success);
}

class UserListFailureState extends UserState {
  final String message;

  const UserListFailureState({required this.message}) : super(status: UserStatus.failure);
}

class UserDeleteLoadingState extends UserState {
  const UserDeleteLoadingState() : super(status: UserStatus.loading);
}

class UserDeleteSuccessState extends UserState {
  const UserDeleteSuccessState() : super(status: UserStatus.success);
}

class UserDeleteFailureState extends UserState {
  final String message;

  const UserDeleteFailureState({required this.message}) : super(status: UserStatus.failure);
}
