part of 'drawer_bloc.dart';

abstract class DrawerEvent extends Equatable {
  const DrawerEvent();

  @override
  List<Object> get props => [];
}

class Logout extends DrawerEvent {
  const Logout();
}

class LoadMenus extends DrawerEvent {
  const LoadMenus({required this.language});

  final String language;

  @override
  List<Object> get props => [language];
}

class RefreshMenus extends DrawerEvent {
  const RefreshMenus();
}

class ChangeLanguageEvent extends DrawerEvent {
  const ChangeLanguageEvent({required this.language});

  final String language;

  @override
  List<Object> get props => [language];
}
