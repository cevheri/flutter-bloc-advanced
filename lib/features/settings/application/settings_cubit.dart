import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/settings/application/usecases/change_language_usecase.dart';
import 'package:flutter_bloc_advance/features/settings/application/usecases/change_theme_usecase.dart';
import 'package:flutter_bloc_advance/features/settings/application/usecases/logout_settings_usecase.dart';

part 'settings_state.dart';

/// Cubit form because every operation is an atomic fire-and-forget call.
///
/// See `CLAUDE.md` → State Management for the project-level rule on when
/// to choose `Cubit` over `Bloc`.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    ChangeLanguageUseCase? changeLanguageUseCase,
    ChangeThemeUseCase? changeThemeUseCase,
    LogoutSettingsUseCase? logoutSettingsUseCase,
  }) : _changeLanguageUseCase = changeLanguageUseCase ?? const ChangeLanguageUseCase(),
       _changeThemeUseCase = changeThemeUseCase ?? const ChangeThemeUseCase(),
       _logoutSettingsUseCase = logoutSettingsUseCase ?? const LogoutSettingsUseCase(),
       super(const SettingsInitial());

  static final _log = AppLogger.getLogger('SettingsCubit');

  final ChangeLanguageUseCase _changeLanguageUseCase;
  final ChangeThemeUseCase _changeThemeUseCase;
  final LogoutSettingsUseCase _logoutSettingsUseCase;

  Future<void> changeLanguage(String? language) async {
    _log.debug('BEGIN: changeLanguage: {}', [language]);
    emit(const SettingsLoading());
    try {
      final result = _changeLanguageUseCase(language);
      emit(SettingsLanguageChanged(language: result));
      _log.debug('END: changeLanguage success');
    } catch (e) {
      emit(const SettingsFailure(message: 'Change Language Error'));
      _log.error('END: changeLanguage failure: {}', [e]);
    }
  }

  Future<void> changeTheme(ThemeMode theme) async {
    _log.debug('BEGIN: changeTheme: {}', [theme.name]);
    emit(const SettingsLoading());
    emit(SettingsThemeChanged(theme: _changeThemeUseCase(theme)));
    _log.debug('END: changeTheme success');
  }

  Future<void> logout() async {
    _log.debug('BEGIN: logout');
    emit(const SettingsLoading());
    await _logoutSettingsUseCase();
    emit(const SettingsLogoutSuccess());
    _log.debug('END: logout success');
  }
}
