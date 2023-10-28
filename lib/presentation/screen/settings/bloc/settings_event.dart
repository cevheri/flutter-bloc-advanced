
part of 'settings_bloc.dart';

class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class SettingsLoadCurrentUser extends SettingsEvent {}


class SettingsFirstNameChanged extends SettingsEvent {
  final String firstName;

  const SettingsFirstNameChanged({required this.firstName});

  @override
  List<Object> get props => [firstName];
}

class SettingsLastNameChanged extends SettingsEvent {
  final String lastName;

  const SettingsLastNameChanged({required this.lastName});

  @override
  List<Object> get props => [lastName];
}

class SettingsEmailChanged extends SettingsEvent {
  final String email;

  const SettingsEmailChanged({required this.email});

  @override
  List<Object> get props => [email];
}

class SettingsLanguageChanged extends SettingsEvent {
  final String language;

  const SettingsLanguageChanged({required this.language});

  @override
  List<Object> get props => [language];
}

class SettingsFormSubmitted extends SettingsEvent {}
