import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/app/shell/menu_list_cache.dart';
import 'package:flutter_bloc_advance/app/shell/models/menu.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/logout_usecase.dart';

part 'menu_event.dart';
part 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc({required this._logoutUseCase, required this._menuRepository}) : super(const MenuState()) {
    on<LoadMenus>(_loadMenus);
    on<RefreshMenus>(_refreshMenus);
    on<Logout>(_onLogout);
  }

  static final _log = AppLogger.getLogger('MenuBloc');

  final LogoutUseCase _logoutUseCase;
  final MenuRepository _menuRepository;

  /// Signs out even when the logout cannot clear all that the session stored, as SessionCubit.endSession does: the
  /// user asked to leave, and staying signed in would keep the session open on this device. The error status then
  /// tells AppSessionListeners to say that stored data stayed behind, and the providerSessionLeft status that the
  /// session at the identity provider may still be active.
  FutureOr<void> _onLogout(Logout event, Emitter<MenuState> emit) async {
    emit(state.copyWith(isLogout: false, status: MenuStateStatus.loading));
    final result = await _logoutUseCase();
    MenuListCache.menus = [];
    switch (result) {
      case Success():
        emit(state.copyWith(isLogout: true, status: MenuStateStatus.success));
      case Failure(:final error) when error.code == AppErrorCode.authOidcLogoutIncomplete.key:
        emit(state.copyWith(isLogout: true, status: MenuStateStatus.providerSessionLeft));
      case Failure(:final error):
        emit(state.copyWith(isLogout: true, status: MenuStateStatus.error));
        _log.error('END:onLogout signed out, but the stored session was not fully cleared: {}', [error.message]);
    }
  }

  FutureOr<void> _loadMenus(LoadMenus event, Emitter<MenuState> emit) async {
    emit(state.copyWith(menus: [], status: MenuStateStatus.loading));
    try {
      if (MenuListCache.menus.isNotEmpty) {
        emit(state.copyWith(menus: MenuListCache.menus, status: MenuStateStatus.success));
        return;
      }
      final menus = await _menuRepository.list();
      if (menus.isEmpty) {
        emit(state.copyWith(menus: menus, status: MenuStateStatus.error));
        return;
      }
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus, status: MenuStateStatus.success));
    } catch (e) {
      emit(state.copyWith(menus: [], status: MenuStateStatus.error));
      _log.error('END:loadMenus LoadMenus event error: {}', [e]);
    }
  }

  FutureOr<void> _refreshMenus(RefreshMenus event, Emitter<MenuState> emit) async {
    emit(state.copyWith(menus: [], status: MenuStateStatus.loading));
    try {
      final menus = await _menuRepository.list();
      MenuListCache.menus = menus;
      emit(state.copyWith(menus: menus, status: MenuStateStatus.success));
    } catch (e) {
      emit(state.copyWith(menus: [], status: MenuStateStatus.error));
      _log.error('END:refreshMenus RefreshMenus event error: {}', [e]);
    }
  }
}
