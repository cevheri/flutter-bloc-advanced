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

class UserEditorInit extends UserEvent {
  const UserEditorInit();

  @override
  List<Object> get props => [];
}

class UserSubmitEvent extends UserEvent {
  final User user;

  const UserSubmitEvent(this.user);

  @override
  List<Object> get props => [user];
}


// class UserCreate extends UserEvent {
//   const UserCreate({required this.user});
//
//   final User user;
//
//   @override
//   List<Object> get props => [];
// }
//
// class UserSaveEvent extends UserEvent {
//   const UserSaveEvent({required this.user});
//
//   final User user;
//
//   @override
//   List<Object> get props => [];
// }
//
// class UserEditEvent extends UserEvent {
//   const UserEditEvent({required this.user});
//
//   final User user;
//
//   @override
//   List<Object> get props => [];
// }

class UserList extends UserEvent {}

class UserFetchEvent extends UserEvent {
  final String id;

  const UserFetchEvent(this.id);

  @override
  List<Object> get props => [id];
}

class UserDeleteEvent extends UserEvent {
  final String id;

  const UserDeleteEvent(this.id);

  @override
  List<Object> get props => [id];
}
