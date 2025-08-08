part of 'user_bloc.dart';

class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class UserSearchEvent extends UserEvent {
  final int page;
  final int size;
  final String? authorities;
  final String? name;

  const UserSearchEvent({this.page = 0, this.size = 10, this.authorities, this.name});
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

class UserSaveCompleteEvent extends UserEvent {
  const UserSaveCompleteEvent();

  @override
  List<Object> get props => [];
}

class UserViewCompleteEvent extends UserEvent {
  const UserViewCompleteEvent();

  @override
  List<Object> get props => [];
}
