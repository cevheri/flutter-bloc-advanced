part of 'drawer_bloc.dart';

class DrawerState extends Equatable {
  final List<Menu> menus;
  final bool isLogout;

  const DrawerState({
    this.menus = const [],
    this.isLogout = false,
  });

  DrawerState copyWith({
    List<Menu>? menus,
    bool? isLogout,
  }) {
    return DrawerState(
      menus: menus ?? this.menus,
      isLogout: isLogout ?? this.isLogout,
    );
  }

  @override
  List<Object> get props => [menus, isLogout];

  @override
  bool get stringify => true;
}
