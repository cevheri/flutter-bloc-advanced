part of 'login_bloc.dart';

/// Sealed hierarchy. The base class carries the two UI-config fields
/// (`loginMethod`, `passwordVisible`) that survive across every variant
/// transition — concurrent-state-access exception (CLAUDE.md → State
/// Modeling). Auth-flow data (`username`, `email`, `otpCode`, error
/// message) lives only on the variants that actually carry it.
sealed class LoginState extends Equatable {
  const LoginState({this.loginMethod = LoginMethod.password, this.passwordVisible = false});

  final LoginMethod loginMethod;
  final bool passwordVisible;
}

final class LoginInitialState extends LoginState {
  const LoginInitialState({super.loginMethod, super.passwordVisible});

  @override
  List<Object?> get props => [loginMethod, passwordVisible];
}

final class LoginLoadingState extends LoginState {
  const LoginLoadingState({this.username, super.loginMethod, super.passwordVisible});

  final String? username;

  @override
  List<Object?> get props => [username, loginMethod, passwordVisible];
}

final class LoginLoadedState extends LoginState {
  const LoginLoadedState({this.username, super.loginMethod, super.passwordVisible});

  final String? username;

  @override
  List<Object?> get props => [username, loginMethod, passwordVisible];
}

final class LoginOtpSentState extends LoginState {
  const LoginOtpSentState({required this.email, super.passwordVisible}) : super(loginMethod: LoginMethod.otp);

  final String email;

  @override
  List<Object?> get props => [email, passwordVisible];
}

final class LoginOtpVerifiedState extends LoginState {
  const LoginOtpVerifiedState({required this.email, this.otpCode, super.passwordVisible})
    : super(loginMethod: LoginMethod.otp);

  final String email;
  final String? otpCode;

  @override
  List<Object?> get props => [email, otpCode, passwordVisible];
}

final class LoginErrorState extends LoginState {
  const LoginErrorState({required this.message, super.loginMethod, super.passwordVisible});

  final String message;

  @override
  List<Object?> get props => [message, loginMethod, passwordVisible];
}
