import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/utils/menu_list_cache.dart';

import '../../../../data/models/menu.dart';
import '../../../../data/repository/login_repository.dart';
import '../../../../data/repository/menu_repository.dart';

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
    try {
      await _loginRepository.logout();
      emit(state.copyWith(isLogout: true));
      MenuListCache.menus = [];
    } catch (e) {
      rethrow;
    }
  }

  FutureOr<void> _loadMenus(LoadMenus event, Emitter<DrawerState> emit) async {
    emit(state.copyWith(menus: []));
    try {
      if (MenuListCache.menus.isNotEmpty) {
        emit(state.copyWith(menus: MenuListCache.menus));
        return;
      }
      final menus = await _menuRepository.getMenus();
      emit(state.copyWith(menus: menus));
    } catch (e) {
      emit(state.copyWith(menus: []));
    }
  }

  FutureOr<void> _refreshMenus(RefreshMenus event, Emitter<DrawerState> emit) async {
    try {
      final menus = await _menuRepository.getMenus();
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus));
    } catch (e) {}
  }
}
