part of 'user_list_bloc.dart';

sealed class UserListState extends Equatable {
  const UserListState();
}

final class UserListInitial extends UserListState {
  const UserListInitial();

  @override
  List<Object?> get props => const [];
}

final class UserListLoading extends UserListState {
  const UserListLoading();

  @override
  List<Object?> get props => const [];
}

final class UserListLoaded extends UserListState {
  const UserListLoaded({required this.users});

  final List<UserEntity> users;

  @override
  List<Object?> get props => [users];
}

/// Emitted after a successful delete so the UI can trigger a refresh
/// and surface a confirmation. The caller typically dispatches
/// [UserListSearch] again immediately to repopulate the table.
final class UserListDeleteSuccess extends UserListState {
  const UserListDeleteSuccess();

  @override
  List<Object?> get props => const [];
}

/// A request failed. The UI shows [errorCode] translated via `errorCode.resolve(context)`; the raw error
/// message only goes to the log.
sealed class UserListFailure extends UserListState {
  const UserListFailure({required this.errorCode});

  final AppErrorCode errorCode;

  @override
  List<Object?> get props => [errorCode];
}

/// Searching for users failed, so there is no list to show.
final class UserListLoadFailure extends UserListFailure {
  const UserListLoadFailure({required super.errorCode});
}

/// Deleting a user failed.
final class UserListDeleteFailure extends UserListFailure {
  const UserListDeleteFailure({required super.errorCode});
}
