part of 'drawer_bloc.dart';

enum DrawerStateStatus { initial, loading, success, error }

class DrawerState extends Equatable {
  final List<Menu> menus;
  final bool isLogout;
  final DrawerStateStatus status;
  final String? language;
  final AdaptiveThemeMode? theme;

  const DrawerState({
    this.menus = const [],
    this.isLogout = false,
    this.status = DrawerStateStatus.initial,
    this.language,
    this.theme,
  });

  DrawerState copyWith({
    List<Menu>? menus,
    bool? isLogout,
    DrawerStateStatus? status,
    String? language,
    AdaptiveThemeMode? theme,
  }) {
    return DrawerState(
      menus: menus ?? this.menus,
      isLogout: isLogout ?? this.isLogout,
      status: status ?? this.status,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object> get props => [status, menus, isLogout];
}

//TODO add default language and theme
class DrawerStateInitial extends DrawerState {
  const DrawerStateInitial() : super(status: DrawerStateStatus.initial);
}

class DrawerStateLoading extends DrawerState {
  const DrawerStateLoading() : super(status: DrawerStateStatus.loading);
}

class DrawerStateLoaded extends DrawerState {
  const DrawerStateLoaded({required super.menus}) : super(status: DrawerStateStatus.success);
}

class DrawerStateError extends DrawerState {
  final String message;

  const DrawerStateError({required this.message}) : super(status: DrawerStateStatus.error);
}

class DrawerLanguageChanged extends DrawerState {
  const DrawerLanguageChanged({required super.language}) : super(status: DrawerStateStatus.success);
}

class DrawerThemeChanged extends DrawerState {
  const DrawerThemeChanged({required super.theme}) : super(status: DrawerStateStatus.success);
}
