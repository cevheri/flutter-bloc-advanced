part of 'menu_bloc.dart';

/// [providerSessionLeft] is a logout that ended the app session in an `oidc` build, but not the session at the identity
/// provider.
enum MenuStateStatus { initial, loading, success, error, providerSessionLeft }

class MenuState extends Equatable {
  const MenuState({this.menus = const [], this.isLogout = false, this.status = MenuStateStatus.initial});

  final List<Menu> menus;
  final bool isLogout;
  final MenuStateStatus status;

  MenuState copyWith({List<Menu>? menus, bool? isLogout, MenuStateStatus? status}) {
    return MenuState(menus: menus ?? this.menus, isLogout: isLogout ?? this.isLogout, status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status, menus, isLogout];
}
