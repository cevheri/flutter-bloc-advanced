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

final class UserListDelete extends UserListEvent {
  const UserListDelete(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
