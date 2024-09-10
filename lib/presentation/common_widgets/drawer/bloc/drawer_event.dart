part of 'drawer_bloc.dart';

abstract class DrawerEvent extends Equatable {
  const DrawerEvent();

  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;
}

class Logout extends DrawerEvent {}

class LoadMenus extends DrawerEvent {}

class RefreshMenus extends DrawerEvent {}
