part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, success, failure }

abstract class SettingsState extends Equatable {
  const SettingsState({required this.status});

  final SettingsStatus status;
}

class SettingsInitial extends SettingsState {
  const SettingsInitial() : super(status: SettingsStatus.initial);

  @override
  List<Object> get props => [status];
}

class SettingsLoading extends SettingsState {
  const SettingsLoading() : super(status: SettingsStatus.loading);

  @override
  List<Object> get props => [status];
}

class SettingsLogoutSuccess extends SettingsState {
  const SettingsLogoutSuccess() : super(status: SettingsStatus.success);

  @override
  List<Object> get props => [status];
}

class SettingsLanguageChanged extends SettingsState {
  const SettingsLanguageChanged({required this.language}) : super(status: SettingsStatus.success);

  final String? language;

  @override
  List<Object> get props => [status, language ?? ''];
}

class SettingsThemeChanged extends SettingsState {
  const SettingsThemeChanged({required this.theme}) : super(status: SettingsStatus.success);

  final ThemeMode theme;

  @override
  List<Object> get props => [theme, status];
}

class SettingsFailure extends SettingsState {
  const SettingsFailure({required this.message}) : super(status: SettingsStatus.failure);

  final String message;

  @override
  List<Object> get props => [message, status];
}
