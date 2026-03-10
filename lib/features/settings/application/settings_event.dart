part of 'settings_bloc.dart';

class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class Logout extends SettingsEvent {
  const Logout();
}

class ChangeLanguage extends SettingsEvent {
  const ChangeLanguage({required this.language});

  final String? language;

  @override
  List<Object> get props => [language ?? ''];
}

class ChangeTheme extends SettingsEvent {
  const ChangeTheme({required this.theme});

  final ThemeMode theme;

  @override
  List<Object> get props => [theme];
}
