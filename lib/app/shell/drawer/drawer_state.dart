part of 'drawer_bloc.dart';

enum DrawerStateStatus { initial, loading, success, error }

class DrawerState extends Equatable {
  const DrawerState({
    this.menus = const [],
    this.isLogout = false,
    this.status = DrawerStateStatus.initial,
    this.language,
  });

  final List<Menu> menus;
  final bool isLogout;
  final DrawerStateStatus status;
  final String? language;

  DrawerState copyWith({List<Menu>? menus, bool? isLogout, DrawerStateStatus? status, String? language}) {
    return DrawerState(
      menus: menus ?? this.menus,
      isLogout: isLogout ?? this.isLogout,
      status: status ?? this.status,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [status, menus, isLogout, language];
}
