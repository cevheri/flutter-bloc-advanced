import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/app/shell/menu_list_cache.dart';
import 'package:flutter_bloc_advance/app/shell/models/menu.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';

part 'drawer_event.dart';
part 'drawer_state.dart';

class DrawerBloc extends Bloc<DrawerEvent, DrawerState> {
  DrawerBloc({required IAuthRepository loginRepository, required MenuRepository menuRepository})
    : _loginRepository = loginRepository,
      _menuRepository = menuRepository,
      super(const DrawerState()) {
    on<LoadMenus>(_loadMenus);
    on<RefreshMenus>(_refreshMenus);
    on<Logout>(_onLogout);
    on<ChangeLanguageEvent>(_onChangeLanguage);
  }

  static final _log = AppLogger.getLogger('DrawerBloc');

  final IAuthRepository _loginRepository;
  final MenuRepository _menuRepository;

  FutureOr<void> _onChangeLanguage(ChangeLanguageEvent event, Emitter<DrawerState> emit) async {
    emit(state.copyWith(language: event.language, status: DrawerStateStatus.loading));
    try {
      await AppLocalStorage().save(StorageKeys.language.name, event.language);
      AppLocalStorageCached.language = event.language;
      emit(state.copyWith(language: event.language, status: DrawerStateStatus.success));
      await S.load(Locale(event.language));
    } catch (e) {
      emit(state.copyWith(language: event.language, status: DrawerStateStatus.error));
      _log.error('END:onChangeLanguage ChangeLanguageEvent event error: {}', [e.toString()]);
    }
  }

  FutureOr<void> _onLogout(Logout event, Emitter<DrawerState> emit) async {
    emit(state.copyWith(isLogout: false, status: DrawerStateStatus.loading));
    try {
      await _loginRepository.logout();
      MenuListCache.menus = [];
      emit(state.copyWith(isLogout: true, status: DrawerStateStatus.success));
    } catch (e) {
      emit(state.copyWith(isLogout: false, status: DrawerStateStatus.error));
      _log.error('END:onLogout Logout event error: {}', [e.toString()]);
    }
  }

  FutureOr<void> _loadMenus(LoadMenus event, Emitter<DrawerState> emit) async {
    emit(state.copyWith(menus: [], status: DrawerStateStatus.loading));
    try {
      if (MenuListCache.menus.isNotEmpty) {
        emit(state.copyWith(menus: MenuListCache.menus, status: DrawerStateStatus.success));
        return;
      }
      final menus = await _menuRepository.list();
      if (menus.isEmpty) {
        emit(state.copyWith(menus: menus, status: DrawerStateStatus.error));
        return;
      }
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus, status: DrawerStateStatus.success, language: event.language));
    } catch (e) {
      emit(state.copyWith(menus: [], status: DrawerStateStatus.error, language: event.language));
      _log.error('END:loadMenus LoadMenus event error: {}', [e.toString()]);
    }
  }

  FutureOr<void> _refreshMenus(RefreshMenus event, Emitter<DrawerState> emit) async {
    emit(state.copyWith(menus: [], status: DrawerStateStatus.loading));
    try {
      final menus = await _menuRepository.list();
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus, status: DrawerStateStatus.success));
    } catch (e) {
      emit(state.copyWith(menus: [], status: DrawerStateStatus.error));
      _log.error('END:refreshMenus RefreshMenus event error: {}', [e.toString()]);
    }
  }
}
