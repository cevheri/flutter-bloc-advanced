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
  const UserState({this.status = UserStatus.initial, this.data, this.userList, this.err});

  final UserEntity? data;
  final UserStatus status;
  final List<UserEntity>? userList;
  final String? err;

  UserState copyWith({UserStatus? status, UserEntity? data, List<UserEntity>? userList, String? err}) {
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
