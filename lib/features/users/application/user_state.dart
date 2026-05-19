part of 'user_bloc.dart';

sealed class UserState extends Equatable {
  const UserState();
}

final class UserInitial extends UserState {
  const UserInitial();

  @override
  List<Object?> get props => const [];
}

/// Loading variant carries [data] forward when a save/refresh starts from
/// an already-loaded editor state. This preserves the form contents during
/// the in-flight submit so the user keeps seeing their edits while the
/// button shows a spinner. Concurrent-state-access exception (see
/// `CLAUDE.md` → State Modeling): without this, sealed semantics would
/// blank the form during every transient transition.
final class UserLoading extends UserState {
  const UserLoading({this.data});

  final UserEntity? data;

  @override
  List<Object?> get props => [data];
}

/// Result of `UserSearchEvent` — list page payload.
final class UserSearchSuccess extends UserState {
  const UserSearchSuccess({required this.userList});

  final List<UserEntity> userList;

  @override
  List<Object?> get props => [userList];
}

/// Result of `UserFetchEvent` — editor pre-load payload.
final class UserFetchSuccess extends UserState {
  const UserFetchSuccess({required this.data});

  final UserEntity data;

  @override
  List<Object?> get props => [data];
}

/// Result of `UserSubmitEvent` / `UserSaveCompleteEvent`. `data` is the
/// updated user when available (carried forward from the previous state
/// when this comes from `UserSaveCompleteEvent`).
final class UserSaveSuccess extends UserState {
  const UserSaveSuccess({this.data});

  final UserEntity? data;

  @override
  List<Object?> get props => [data];
}

/// Result of `UserDeleteEvent`.
final class UserDeleteSuccess extends UserState {
  const UserDeleteSuccess();

  @override
  List<Object?> get props => const [];
}

/// Result of `UserViewCompleteEvent`. `data` is carried forward from the
/// previous editor state so the list-page refresh trigger can still see
/// the user that was being viewed.
final class UserViewSuccess extends UserState {
  const UserViewSuccess({this.data});

  final UserEntity? data;

  @override
  List<Object?> get props => [data];
}

final class UserFailure extends UserState {
  const UserFailure({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}
