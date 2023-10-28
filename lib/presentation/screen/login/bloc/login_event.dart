part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;
}

class TogglePasswordVisibility extends LoginEvent {
  const TogglePasswordVisibility();
}

class LoginFormSubmitted extends LoginEvent {
  final String username;
  final String password;

  const LoginFormSubmitted({
    required this.username,
    required this.password,
  });
}