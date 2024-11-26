import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/menu.dart';
import '../../../../data/repository/login_repository.dart';
import '../../../../data/repository/menu_repository.dart';
import '../../../../utils/menu_list_cache.dart';

part 'drawer_event.dart';
part 'drawer_state.dart';

class DrawerBloc extends Bloc<DrawerEvent, DrawerState> {
  final LoginRepository _loginRepository;
  final MenuRepository _menuRepository;

  DrawerBloc({
    required LoginRepository loginRepository,
    required MenuRepository menuRepository,
  })  : _loginRepository = loginRepository,
        _menuRepository = menuRepository,
        super(const DrawerState()) {
    on<LoadMenus>(_loadMenus);
    on<RefreshMenus>(_refreshMenus);
    on<Logout>(_onLogout);
  }

  FutureOr<void> _onLogout(Logout event, Emitter<DrawerState> emit) async {
    emit(const DrawerState(isLogout: false));
    try {
      await _loginRepository.logout();
      emit(state.copyWith(isLogout: true));
      MenuListCache.menus = [];
    } catch (e) {
      emit(const DrawerState(isLogout: false));
    }
  }

  FutureOr<void> _loadMenus(LoadMenus event, Emitter<DrawerState> emit) async {
    emit(const DrawerState(menus: []));
    try {
      if (MenuListCache.menus.isNotEmpty) {
        emit(state.copyWith(menus: MenuListCache.menus));
        return;
      }
      final menus = await _menuRepository.getMenus();
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus));
    } catch (e) {
      emit(const DrawerState(menus: []));
    }
  }

  FutureOr<void> _refreshMenus(RefreshMenus event, Emitter<DrawerState> emit) async {
    emit(const DrawerState(menus: []));
    try {
      final menus = await _menuRepository.getMenus();
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus));
    } catch (e) {
      emit(const DrawerState(menus: []));
    }
  }
}
