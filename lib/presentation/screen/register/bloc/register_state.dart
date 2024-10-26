part of 'register_bloc.dart';

enum RegisterStatus { none, authenticating, authenticated, failure }

class RegisterState extends Equatable {
  final String email;
  final RegisterStatus status;

  static final String authenticationFailKey = 'error.authenticate';

  const RegisterState({
    this.email = '',
    this.status = RegisterStatus.none,
  });

  RegisterState copyWith({
    String? email,
    RegisterStatus? status,
  }) {
    return RegisterState(
      email: email ?? this.email,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [email, status];

  @override
  bool get stringify => true;
}

class RegisterInitialState extends RegisterState {}

class RegisterCompletedState extends RegisterState {}

class RegisterErrorState extends RegisterState {
  final String message;

  const RegisterErrorState({required this.message});
}
