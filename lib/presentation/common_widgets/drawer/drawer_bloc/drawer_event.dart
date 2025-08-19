part of 'drawer_bloc.dart';

abstract class DrawerEvent extends Equatable {
  const DrawerEvent();

  @override
  List<Object> get props => [];
}

class Logout extends DrawerEvent {}

class LoadMenus extends DrawerEvent {
  final String language;

  const LoadMenus({required this.language});

  @override
  List<Object> get props => [language];
}

class RefreshMenus extends DrawerEvent {}

class ChangeLanguageEvent extends DrawerEvent {
  final String language;

  const ChangeLanguageEvent({required this.language});

  @override
  List<Object> get props => [language];
}
