import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// Bloc responsible for managing the Settings.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static final _log = AppLogger.getLogger("SettingsBloc");

  SettingsBloc() : super(const SettingsInitial()) {
    on<ChangeLanguage>(_onChangeLanguage);
    on<ChangeTheme>(_onChangeTheme);
    on<Logout>(_onLogout);
  }

  FutureOr<void> _onChangeLanguage(ChangeLanguage event, Emitter<SettingsState> emit) async {
    _log.debug("BEGIN: onChangeLanguage ChangeLanguage event: {}", [event.language]);
    emit(const SettingsLoading());
    try {
      if (event.language == null || event.language!.isEmpty) {
        throw Exception("Language is null");
      } else {
        // Change the language
        emit(SettingsLanguageChanged(language: event.language));
        _log.debug("END:onChangeLanguage ChangeLanguage event success");
      }
    } catch (e) {
      emit(const SettingsFailure(message: "Change Language Error"));
      _log.error("END:onChangeLanguage ChangeLanguage event failure: {}", ["Change Language Error"]);
    }
  }

  FutureOr<void> _onChangeTheme(ChangeTheme event, Emitter<SettingsState> emit) async {
    _log.debug("BEGIN: onChangeTheme ChangeTheme event: {}", [event.theme.name]);
    emit(const SettingsLoading());

    // Change the theme
    emit(SettingsThemeChanged(theme: event.theme));
    _log.debug("END:onChangeTheme ChangeTheme event success");
  }

  FutureOr<void> _onLogout(Logout event, Emitter<SettingsState> emit) async {
    _log.debug("BEGIN: onLogout Logout event: {}", []);
    emit(const SettingsLoading());

    emit(const SettingsLogoutSuccess());
    _log.debug("END:onLogout Logout event success: {}", []);
  }
}
