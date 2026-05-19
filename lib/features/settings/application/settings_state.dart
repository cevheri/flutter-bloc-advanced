part of 'settings_cubit.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();
}

final class SettingsInitial extends SettingsState {
  const SettingsInitial();

  @override
  List<Object?> get props => const [];
}

final class SettingsLoading extends SettingsState {
  const SettingsLoading();

  @override
  List<Object?> get props => const [];
}

final class SettingsLogoutSuccess extends SettingsState {
  const SettingsLogoutSuccess();

  @override
  List<Object?> get props => const [];
}

final class SettingsLanguageChanged extends SettingsState {
  const SettingsLanguageChanged({required this.language});

  final String? language;

  @override
  List<Object?> get props => [language];
}

final class SettingsThemeChanged extends SettingsState {
  const SettingsThemeChanged({required this.theme});

  final ThemeMode theme;

  @override
  List<Object?> get props => [theme];
}

final class SettingsFailure extends SettingsState {
  const SettingsFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
