part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();
}

class TogglePasswordVisibility extends LoginEvent {
  const TogglePasswordVisibility();

  @override
  List<Object?> get props => [];
}

class LoginFormSubmitted extends LoginEvent {
  final String username;
  final String password;

  const LoginFormSubmitted({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

enum LoginMethod { otp, password }

class ChangeLoginMethod extends LoginEvent {
  final LoginMethod method;

  const ChangeLoginMethod({required this.method});

  @override
  List<Object?> get props => [method];
}

class SendOtpRequested extends LoginEvent {
  final String email;

  const SendOtpRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class VerifyOtpSubmitted extends LoginEvent {
  final String email;
  final String otpCode;

  const VerifyOtpSubmitted({required this.email, required this.otpCode});

  @override
  List<Object?> get props => [email, otpCode];
}
