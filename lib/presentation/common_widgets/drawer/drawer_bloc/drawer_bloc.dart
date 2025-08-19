import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';

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

  DrawerBloc({required LoginRepository loginRepository, required MenuRepository menuRepository})
    : _loginRepository = loginRepository,
      _menuRepository = menuRepository,
      super(const DrawerState()) {
    on<LoadMenus>(_loadMenus);
    on<RefreshMenus>(_refreshMenus);
    on<Logout>(_onLogout);
    on<ChangeLanguageEvent>(_onChangeLanguage);
  }

  FutureOr<void> _onChangeLanguage(ChangeLanguageEvent event, Emitter<DrawerState> emit) async {
    _log.debug("BEGIN: onChangeLanguage ChangeLanguageEvent event: {}", []);
    emit(state.copyWith(language: event.language, status: DrawerStateStatus.loading));
    try {
      await AppLocalStorage().save(StorageKeys.language.name, event.language);
      // update in-memory cache immediately
      AppLocalStorageCached.language = event.language;
      emit(state.copyWith(language: event.language, status: DrawerStateStatus.success));

      await S.load(Locale(event.language));

      _log.debug("END:onChangeLanguage ChangeLanguageEvent event success: {}", [event.language]);
    } catch (e) {
      emit(state.copyWith(language: event.language, status: DrawerStateStatus.error));
      _log.error("END:onChangeLanguage ChangeLanguageEvent event error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _onLogout(Logout event, Emitter<DrawerState> emit) async {
    _log.debug("BEGIN: onLogout Logout event: {} {}", [state.status, event]);
    emit(state.copyWith(isLogout: false, status: DrawerStateStatus.loading));

    try {
      await _loginRepository.logout();
      MenuListCache.menus = [];
      emit(state.copyWith(isLogout: true, status: DrawerStateStatus.success));
      _log.debug("END:onLogout Logout event success: {}");
    } catch (e) {
      emit(state.copyWith(isLogout: false, status: DrawerStateStatus.error));
      _log.error("END:onLogout Logout event error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _loadMenus(LoadMenus event, Emitter<DrawerState> emit) async {
    _log.debug("BEGIN: loadMenus LoadMenus event: {}", []);
    // Keep language/theme unchanged during loading to avoid unexpected state diffs in tests
    emit(state.copyWith(menus: [], status: DrawerStateStatus.loading));
    try {
      if (MenuListCache.menus.isNotEmpty) {
        emit(state.copyWith(menus: MenuListCache.menus, status: DrawerStateStatus.success));
        _log.info("END:loadMenus read from cache: {}", []);
        return;
      }
      final menus = await _menuRepository.list();
      if (menus.isEmpty) {
        emit(state.copyWith(menus: menus, status: DrawerStateStatus.error));
        return;
      }
      MenuListCache.menus = menus;
      // Apply language when loading is complete
      emit(state.copyWith(menus: menus, status: DrawerStateStatus.success, language: event.language));
      _log.debug("END:loadMenus LoadMenus event success: {}", []);
    } catch (e) {
      emit(state.copyWith(menus: [], status: DrawerStateStatus.error, language: event.language));
      _log.error("END:loadMenus LoadMenus event error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _refreshMenus(RefreshMenus event, Emitter<DrawerState> emit) async {
    _log.debug("BEGIN: refreshMenus RefreshMenus event: {}", []);
    emit(state.copyWith(menus: [], status: DrawerStateStatus.loading));
    try {
      final menus = await _menuRepository.list();
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus, status: DrawerStateStatus.success));
      _log.debug("END:refreshMenus RefreshMenus event success: {}", []);
    } catch (e) {
      emit(state.copyWith(menus: [], status: DrawerStateStatus.error));
      _log.error("END:refreshMenus RefreshMenus event error: {}", [e.toString()]);
    }
  }
}
