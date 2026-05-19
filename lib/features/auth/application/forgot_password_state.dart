part of 'forgot_password_bloc.dart';

enum ForgotPasswordStatus { initial, loading, success, failure }

class ForgotPasswordState extends Equatable {
  final String? email;
  final ForgotPasswordStatus status;
  final String? errorMessage;

  const ForgotPasswordState({this.email, this.status = ForgotPasswordStatus.initial, this.errorMessage});

  ForgotPasswordState copyWith({String? email, ForgotPasswordStatus? status, String? errorMessage}) {
    return ForgotPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, email, errorMessage];

  @override
  bool get stringify => true;
}

class ForgotPasswordInitialState extends ForgotPasswordState {
  const ForgotPasswordInitialState() : super(status: ForgotPasswordStatus.initial);
}

class ForgotPasswordLoadingState extends ForgotPasswordState {
  const ForgotPasswordLoadingState() : super(status: ForgotPasswordStatus.loading);
}

class ForgotPasswordCompletedState extends ForgotPasswordState {
  const ForgotPasswordCompletedState() : super(status: ForgotPasswordStatus.success);
}

class ForgotPasswordErrorState extends ForgotPasswordState {
  final String message;

  const ForgotPasswordErrorState({required this.message}) : super(status: ForgotPasswordStatus.failure);

  @override
  List<Object?> get props => [status, message];
}
