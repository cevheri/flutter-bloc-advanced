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
  const LoadMenus();
}

class RefreshMenus extends MenuEvent {
  const RefreshMenus();
}
