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
import 'package:flutter_bloc_advance/features/auth/application/usecases/sso_sign_out_usecase.dart';

part 'menu_event.dart';
part 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc({required this._logoutUseCase, required this._menuRepository, this._ssoSignOutUseCase})
    : super(const MenuState()) {
    on<LoadMenus>(_loadMenus);
    on<RefreshMenus>(_refreshMenus);
    on<Logout>(_onLogout);
  }

  static final _log = AppLogger.getLogger('MenuBloc');

  final LogoutUseCase _logoutUseCase;
  final MenuRepository _menuRepository;

  /// The logout of an `oidc` build, which runs instead of [_logoutUseCase]; null in a `jwt` build.
  final SsoSignOutUseCase? _ssoSignOutUseCase;

  /// Signs out even when the logout cannot clear all that the session stored, as SessionCubit.endSession does: the
  /// user asked to leave, and staying signed in would keep the session open on this device. The error status then
  /// tells AppSessionListeners to say that stored data stayed behind, and the providerSessionLeft status that the
  /// session at the identity provider may still be active.
  FutureOr<void> _onLogout(Logout event, Emitter<MenuState> emit) async {
    emit(state.copyWith(isLogout: false, status: MenuStateStatus.loading));
    final ssoSignOut = _ssoSignOutUseCase;
    if (ssoSignOut != null) return _onSsoLogout(ssoSignOut, emit);
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

  /// The logout of an `oidc` build signs out as soon as the session on this device is cleared, so the login page shows
  /// while the provider logout goes on, which on desktop can wait for the browser for minutes. When the provider
  /// logout then fails, the providerSessionLeft status follows, unless the wipe failed: the error status stays, since
  /// data left on this device matters more.
  Future<void> _onSsoLogout(SsoSignOutUseCase signOut, Emitter<MenuState> emit) async {
    final signedOut = await signOut();
    MenuListCache.menus = [];
    switch (signedOut.cleared) {
      case Success():
        emit(state.copyWith(isLogout: true, status: MenuStateStatus.success));
      case Failure(:final error):
        emit(state.copyWith(isLogout: true, status: MenuStateStatus.error));
        _log.error('END:onLogout signed out, but the stored session was not fully cleared: {}', [error.message]);
    }
    final providerLogout = await signedOut.providerLogout;
    if (providerLogout is Failure && signedOut.cleared is Success) {
      emit(state.copyWith(status: MenuStateStatus.providerSessionLeft));
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
