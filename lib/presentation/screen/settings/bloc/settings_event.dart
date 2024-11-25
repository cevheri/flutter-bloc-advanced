part of 'settings_bloc.dart';

class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class Logout extends SettingsEvent {}

class ChangeLanguage extends SettingsEvent {
  final String? language;

  const ChangeLanguage({required this.language});

  @override
  List<Object> get props => [language ?? ""];
}

class ChangeTheme extends SettingsEvent {
  final AdaptiveThemeMode theme;

  const ChangeTheme({required this.theme});

  @override
  List<Object> get props => [theme];
}
