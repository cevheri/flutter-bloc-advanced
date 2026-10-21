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

  /// The password is masked: the debug observer records the text of every event in the dev console.
  @override
  String toString() => 'LoginFormSubmitted(username: $username, password: $secretMask)';
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

  /// The code is masked: the debug observer records the text of every event in the dev console.
  @override
  String toString() => 'VerifyOtpSubmitted(email: $email, otpCode: $secretMask)';
}

/// Starts a sign-in through the OpenID Connect provider. On web the tab lands on [webReturnPath] when it comes back
/// from the provider; [browserDoneMessage] is the page a desktop browser shows once the app has the answer.
final class SsoSignInRequested extends LoginEvent {
  const SsoSignInRequested({this.webReturnPath, required this.browserDoneMessage});

  final String? webReturnPath;
  final String browserDoneMessage;

  @override
  List<Object?> get props => [webReturnPath, browserDoneMessage];
}

/// Returns to a blank sign-in when the session ends: the next user must not inherit the signed-out user's name and
/// roles, nor a password shown in plain text.
class LoginReset extends LoginEvent {
  const LoginReset();

  @override
  List<Object?> get props => [];
}
