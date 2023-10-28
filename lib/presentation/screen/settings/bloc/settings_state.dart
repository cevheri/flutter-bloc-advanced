part of 'settings_bloc.dart';

enum SettingsStatus { none, loading, loaded, failure }

class SettingsState extends Equatable {
  final String firstName;
  final String lastName;
  final String email;
  final String language;
  final SettingsStatus status;

  /// Default constructor for this class
  const SettingsState({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.language = 'en',
    this.status = SettingsStatus.none,
  });

  SettingsState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? language,
    SettingsStatus? status,
  }) {
    return SettingsState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      language: language ?? this.language,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [firstName, lastName, email, language, status];

  @override
  bool get stringify => true;
}
