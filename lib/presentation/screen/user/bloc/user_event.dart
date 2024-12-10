part of 'user_bloc.dart';

class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class UserSearch extends UserEvent {
  final int rangeStart;
  final int rangeEnd;
  final String authority;
  final String name;

  const UserSearch(
    this.rangeStart,
    this.rangeEnd,
    this.authority,
    this.name,
  );
}

class UserCreate extends UserEvent {
  const UserCreate({required this.user});

  final User user;

  @override
  List<Object> get props => [];
}

class UserUpdate extends UserEvent {
  const UserUpdate({required this.user});

  final User user;

  @override
  List<Object> get props => [];
}

class UserEdit extends UserEvent {
  const UserEdit({required this.user});

  final User user;

  @override
  List<Object> get props => [];
}

class UserList extends UserEvent {}

class FetchUserEvent extends UserEvent {
  final String id;

  const FetchUserEvent(this.id);

  @override
  List<Object> get props => [id];
}
