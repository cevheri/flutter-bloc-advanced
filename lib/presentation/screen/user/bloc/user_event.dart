part of 'user_bloc.dart';

class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class UserSearch extends UserEvent {
  final int rangeStart;
  final int rangeEnd;
  final String authorities;
  final String name;

  const UserSearch(
    this.rangeStart,
    this.rangeEnd,
    this.authorities,
    this.name,
  );
}

class UserCreate extends UserEvent {
  const UserCreate({
    required this.user,
  });

  final User user;

  @override
  List<Object> get props => [];
}

class UserUpdate extends UserEvent {
  const UserUpdate({
    required this.user,
  });

  final User user;

  @override
  List<Object> get props => [];
}

class UserEdit extends UserEvent {
  const UserEdit({
    required this.user,
  });

  final User user;

  @override
  List<Object> get props => [];
}

class UserList extends UserEvent {}
