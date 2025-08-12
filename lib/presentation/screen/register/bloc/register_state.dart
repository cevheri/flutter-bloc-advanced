part of 'register_bloc.dart';

enum RegisterStatus { initial, loading, success, error }

class RegisterState extends Equatable {
  final User? data;
  final RegisterStatus status;

  const RegisterState({this.data, this.status = RegisterStatus.initial});

  RegisterState copyWith({User? data, RegisterStatus? status}) {
    return RegisterState(data: data ?? this.data, status: status ?? this.status);
  }

  @override
  List<Object> get props => [status, data ?? ''];

  @override
  bool get stringify => true;
}

class RegisterInitialState extends RegisterState {
  const RegisterInitialState() : super(status: RegisterStatus.initial);
}

class RegisterLoadingState extends RegisterState {
  const RegisterLoadingState() : super(status: RegisterStatus.loading);
}

class RegisterCompletedState extends RegisterState {
  const RegisterCompletedState({required User user}) : super(data: user, status: RegisterStatus.success);
}

class RegisterErrorState extends RegisterState {
  final String message;

  const RegisterErrorState({required this.message}) : super(status: RegisterStatus.error);
}
