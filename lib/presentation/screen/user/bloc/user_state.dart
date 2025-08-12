part of 'user_bloc.dart';

enum UserStatus {
  initial,
  loading,
  success,
  failure,
  searchSuccess,
  fetchSuccess,
  deleteSuccess,
  saveSuccess,
  viewSuccess,
}

class UserState extends Equatable {
  final User? data;
  final UserStatus status;
  final List<User>? userList;
  final String? err;

  const UserState({this.status = UserStatus.initial, this.data, this.userList, this.err});

  UserState copyWith({UserStatus? status, User? data, List<User>? userList, String? err}) {
    return UserState(
      status: status ?? this.status,
      data: data ?? this.data,
      userList: userList ?? this.userList,
      err: err ?? this.err,
    );
  }

  @override
  List<Object?> get props => [status, data, userList, err];
}
