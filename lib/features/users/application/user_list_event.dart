part of 'user_list_bloc.dart';

sealed class UserListEvent extends Equatable {
  const UserListEvent();

  @override
  List<Object?> get props => const [];
}

final class UserListSearch extends UserListEvent {
  const UserListSearch({this.page = 0, this.size = 10, this.authorities, this.name});

  final int page;
  final int size;
  final String? authorities;
  final String? name;

  @override
  List<Object?> get props => [page, size, authorities, name];
}

/// Deletes the user with [login], the identifier the API deletes a user by.
final class UserListDelete extends UserListEvent {
  const UserListDelete(this.login);

  final String login;

  @override
  List<Object?> get props => [login];
}
