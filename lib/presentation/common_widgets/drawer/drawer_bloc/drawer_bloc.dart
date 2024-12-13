import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

import '../../../../data/models/menu.dart';
import '../../../../data/repository/login_repository.dart';
import '../../../../data/repository/menu_repository.dart';
import '../../../../utils/menu_list_cache.dart';

part 'drawer_event.dart';
part 'drawer_state.dart';

class DrawerBloc extends Bloc<DrawerEvent, DrawerState> {
  static final _log = AppLogger.getLogger("DrawerBloc");
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
    _log.debug("BEGIN: onLogout Logout event: {}", []);
    emit(const DrawerState(isLogout: false, status: DrawerStateStatus.loading));
    try {
      await _loginRepository.logout();
      emit(state.copyWith(isLogout: true, status: DrawerStateStatus.loaded));
      MenuListCache.menus = [];
      _log.debug("END:onLogout Logout event success: {}", []);
    } catch (e) {
      emit(const DrawerState(isLogout: false, status: DrawerStateStatus.error));
      _log.error("END:onLogout Logout event error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _loadMenus(LoadMenus event, Emitter<DrawerState> emit) async {
    _log.debug("BEGIN: loadMenus LoadMenus event: {}", []);
    emit(const DrawerState(menus: [], status: DrawerStateStatus.loading));
    try {
      if (MenuListCache.menus.isNotEmpty) {
        emit(state.copyWith(menus: MenuListCache.menus, status: DrawerStateStatus.loaded));
        _log.info("END:loadMenus read from cache: {}", []);
        return;
      }
      final menus = await _menuRepository.getMenus();
      if(menus.isEmpty) {
        emit(const DrawerState(menus: [], status: DrawerStateStatus.error));
        return;
      }
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus, status: DrawerStateStatus.loaded));
      _log.debug("END:loadMenus LoadMenus event success: {}", []);
    } catch (e) {
      emit(const DrawerState(menus: [], status: DrawerStateStatus.error));
      _log.error("END:loadMenus LoadMenus event error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _refreshMenus(RefreshMenus event, Emitter<DrawerState> emit) async {
    _log.debug("BEGIN: refreshMenus RefreshMenus event: {}", []);
    emit(const DrawerState(menus: [], status: DrawerStateStatus.loading));
    try {
      final menus = await _menuRepository.getMenus();
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus, status: DrawerStateStatus.loaded));
      _log.debug("END:refreshMenus RefreshMenus event success: {}", []);
    } catch (e) {
      emit(const DrawerState(menus: [], status: DrawerStateStatus.error));
      _log.error("END:refreshMenus RefreshMenus event error: {}", [e.toString()]);
    }
  }
}
