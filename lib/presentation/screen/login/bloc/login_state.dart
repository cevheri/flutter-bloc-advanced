part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final String? username;
  final String? password;
  final LoginStatus status;
  final bool passwordVisible;

  static const String authenticationFailKey = 'error.authenticate';

  const LoginState({
    this.username,
    this.password,
    this.status = LoginStatus.initial,
    this.passwordVisible = false,
  });

  LoginState copyWith({
    String? username,
    String? password,
    LoginStatus? status,
    bool? passwordVisible,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      passwordVisible: passwordVisible ?? this.passwordVisible,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [username, password, status, passwordVisible];
}

class LoginInitialState extends LoginState {}

class LoginLoadingState extends LoginState {}

class LoginLoadedState extends LoginState {}

class LoginErrorState extends LoginState {
  final String message;

  const LoginErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
