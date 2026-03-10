part of 'menu_bloc.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object> get props => [];
}

class Logout extends MenuEvent {
  const Logout();
}

class LoadMenus extends MenuEvent {
  const LoadMenus({required this.language});

  final String language;

  @override
  List<Object> get props => [language];
}

class RefreshMenus extends MenuEvent {
  const RefreshMenus();
}

class ChangeLanguageEvent extends MenuEvent {
  const ChangeLanguageEvent({required this.language});

  final String language;

  @override
  List<Object> get props => [language];
}
