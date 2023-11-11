import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/models/menu.dart';
import '../../../../data/repository/login_repository.dart';
import '../../../../data/repository/menu_repository.dart';
import '../../../../utils/menu_list_cache.dart';

part 'drawer_event.dart';

part 'drawer_state.dart';

class DrawerBloc extends Bloc<DrawerEvent, DrawerState> {
  final LoginRepository _loginRepository;
  final MenuRepository _menuRepository;

  DrawerBloc({ required LoginRepository loginRepository,required MenuRepository menuRepository,})  : _loginRepository = loginRepository,
        _menuRepository = menuRepository,
        super(const DrawerState()) {
    on<LoadMenus>(_loadMenus);
    on<RefreshMenus>(_refreshMenus);
    on<Logout>(_onLogout);
  }



  FutureOr<void> _onLogout(Logout event, Emitter<DrawerState> emit) async {
    log("DrawerBloc start _onLogout");
    try {

      await _loginRepository.logout();
      emit(state.copyWith(isLogout: true));

      MenuListCache.menus = [];
      //TODO clear token

      log("DrawerBloc end _onLogout");
    } catch (e) {
      log("DrawerBloc _onLogout error: $e");
    }
  }

  FutureOr<void> _loadMenus(LoadMenus event, Emitter<DrawerState> emit) async {
    log("DrawerBloc start _loadMenus");
    emit(state.copyWith(menus: []));
    try {
      if(MenuListCache.menus.isNotEmpty){
        emit(state.copyWith(menus: MenuListCache.menus));
        log("DrawerBloc end _loadMenus from cache");
        return;
      }
      final menus = await _menuRepository.getMenus();
      emit(state.copyWith(menus: menus));
      log("DrawerBloc end _loadMenus from api");
    } catch (e) {
      emit(state.copyWith(menus: []));
      log("DrawerBloc _loadMenus error: $e");
    }
  }

  FutureOr<void> _refreshMenus(RefreshMenus event, Emitter<DrawerState> emit) async {
    log("DrawerBloc start _refreshMenus");
    try {
      final menus = await _menuRepository.getMenus();
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus));
      log("DrawerBloc end _refreshMenus");
    } catch (e) {
      log("DrawerBloc _refreshMenus error: $e");
    }
  }

}
