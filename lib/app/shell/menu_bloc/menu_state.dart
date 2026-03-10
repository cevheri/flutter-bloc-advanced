part of 'menu_bloc.dart';

enum MenuStateStatus { initial, loading, success, error }

class MenuState extends Equatable {
  const MenuState({this.menus = const [], this.isLogout = false, this.status = MenuStateStatus.initial, this.language});

  final List<Menu> menus;
  final bool isLogout;
  final MenuStateStatus status;
  final String? language;

  MenuState copyWith({List<Menu>? menus, bool? isLogout, MenuStateStatus? status, String? language}) {
    return MenuState(
      menus: menus ?? this.menus,
      isLogout: isLogout ?? this.isLogout,
      status: status ?? this.status,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [status, menus, isLogout, language];
}
