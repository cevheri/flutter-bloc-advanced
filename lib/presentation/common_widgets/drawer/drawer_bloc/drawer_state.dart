part of 'drawer_bloc.dart';

enum DrawerStateStatus { initial, loading, loaded, error }

class DrawerState extends Equatable {
  final List<Menu> menus;
  final bool isLogout;
  final DrawerStateStatus status;

  const DrawerState({
    this.menus = const [],
    this.isLogout = false,
    this.status = DrawerStateStatus.initial,
  });

  DrawerState copyWith({
    List<Menu>? menus,
    bool? isLogout,
    DrawerStateStatus? status,
  }) {
    return DrawerState(
      menus: menus ?? this.menus,
      isLogout: isLogout ?? this.isLogout,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [status, menus, isLogout];
}

class DrawerStateInitial extends DrawerState {
  const DrawerStateInitial() : super(status: DrawerStateStatus.initial);
}

class DrawerStateLoading extends DrawerState {
  const DrawerStateLoading() : super(status: DrawerStateStatus.loading);
}

class DrawerStateLoaded extends DrawerState {
  const DrawerStateLoaded({required super.menus}) : super(status: DrawerStateStatus.loaded);
}

class DrawerStateError extends DrawerState {
  final String message;

  const DrawerStateError({required this.message}) : super(status: DrawerStateStatus.error);
}