part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final String? username;
  final String? password;
  final LoginStatus status;
  final bool passwordVisible;
  final String? email;
  final String? otpCode;
  final bool isOtpSent;
  final LoginMethod loginMethod;
  static const String authenticationFailKey = 'error.authenticate';

  const LoginState({
    this.username,
    this.password,
    this.status = LoginStatus.initial,
    this.passwordVisible = false,
    this.email,
    this.otpCode,
    this.isOtpSent = false,
    this.loginMethod = LoginMethod.password,
  });

  LoginState copyWith({
    String? username,
    String? password,
    LoginStatus? status,
    bool? passwordVisible,
    String? email,
    String? otpCode,
    bool? isOtpSent,
    LoginMethod? loginMethod,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      passwordVisible: passwordVisible ?? this.passwordVisible,
      email: email ?? this.email,
      otpCode: otpCode ?? this.otpCode,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      loginMethod: loginMethod ?? this.loginMethod,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [username, password, status, passwordVisible, email, otpCode, isOtpSent, loginMethod];
}

class LoginInitialState extends LoginState {
  const LoginInitialState() : super(status: LoginStatus.initial);
}

class LoginLoadingState extends LoginState {
  const LoginLoadingState({super.username, super.password}) : super(status: LoginStatus.loading);

  @override
  List<Object?> get props => [username, password, status];
}

class LoginLoadedState extends LoginState {
  const LoginLoadedState({super.username, super.password}) : super(status: LoginStatus.success);

  @override
  List<Object?> get props => [username, password, status];
}

class LoginOtpSentState extends LoginState {
  const LoginOtpSentState({super.email}) : super(status: LoginStatus.success, isOtpSent: true);

  @override
  List<Object?> get props => [email, status];
}

class LoginOtpVerifiedState extends LoginState {
  const LoginOtpVerifiedState({super.email, super.otpCode}) : super(status: LoginStatus.success);

  @override
  List<Object?> get props => [email, otpCode, status];
}

class LoginErrorState extends LoginState {
  final String message;

  const LoginErrorState({required this.message}) : super(status: LoginStatus.failure);

  @override
  List<Object?> get props => [message];
}
