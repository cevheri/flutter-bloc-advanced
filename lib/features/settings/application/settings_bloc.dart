import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/settings/application/usecases/change_language_usecase.dart';
import 'package:flutter_bloc_advance/features/settings/application/usecases/change_theme_usecase.dart';
import 'package:flutter_bloc_advance/features/settings/application/usecases/logout_settings_usecase.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    ChangeLanguageUseCase? changeLanguageUseCase,
    ChangeThemeUseCase? changeThemeUseCase,
    LogoutSettingsUseCase? logoutSettingsUseCase,
  }) : _changeLanguageUseCase = changeLanguageUseCase ?? const ChangeLanguageUseCase(),
       _changeThemeUseCase = changeThemeUseCase ?? const ChangeThemeUseCase(),
       _logoutSettingsUseCase = logoutSettingsUseCase ?? const LogoutSettingsUseCase(),
       super(const SettingsInitial()) {
    on<Logout>(_onLogout);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ChangeTheme>(_onChangeTheme);
  }

  static final _log = AppLogger.getLogger('SettingsBloc');

  final ChangeLanguageUseCase _changeLanguageUseCase;
  final ChangeThemeUseCase _changeThemeUseCase;
  final LogoutSettingsUseCase _logoutSettingsUseCase;

  FutureOr<void> _onChangeLanguage(ChangeLanguage event, Emitter<SettingsState> emit) async {
    _log.debug('BEGIN: onChangeLanguage ChangeLanguage event: {}', [event.language]);
    emit(const SettingsLoading());
    try {
      final language = _changeLanguageUseCase(event.language);
      emit(SettingsLanguageChanged(language: language));
      _log.debug('END:onChangeLanguage ChangeLanguage event success');
    } catch (e) {
      emit(const SettingsFailure(message: 'Change Language Error'));
      _log.error('END:onChangeLanguage ChangeLanguage event failure: {}', ['Change Language Error']);
    }
  }

  FutureOr<void> _onChangeTheme(ChangeTheme event, Emitter<SettingsState> emit) async {
    _log.debug('BEGIN: onChangeTheme ChangeTheme event: {}', [event.theme.name]);
    emit(const SettingsLoading());
    emit(SettingsThemeChanged(theme: _changeThemeUseCase(event.theme)));
    _log.debug('END:onChangeTheme ChangeTheme event success');
  }

  FutureOr<void> _onLogout(Logout event, Emitter<SettingsState> emit) async {
    _log.debug('BEGIN: onLogout Logout event: {}', []);
    emit(const SettingsLoading());
    await _logoutSettingsUseCase();
    emit(const SettingsLogoutSuccess());
    _log.debug('END:onLogout Logout event success: {}', []);
  }
}
