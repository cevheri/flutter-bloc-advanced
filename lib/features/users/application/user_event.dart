part of 'user_bloc.dart';

class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class UserSearchEvent extends UserEvent {
  const UserSearchEvent({this.page = 0, this.size = 10, this.authorities, this.name});

  final int page;
  final int size;
  final String? authorities;
  final String? name;
}

class UserEditorInit extends UserEvent {
  const UserEditorInit();

  @override
  List<Object> get props => [];
}

class UserSubmitEvent extends UserEvent {
  const UserSubmitEvent(this.user);

  final UserEntity user;

  @override
  List<Object> get props => [user];
}

class UserFetchEvent extends UserEvent {
  const UserFetchEvent(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

class UserDeleteEvent extends UserEvent {
  const UserDeleteEvent(this.id);

  final String id;

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
