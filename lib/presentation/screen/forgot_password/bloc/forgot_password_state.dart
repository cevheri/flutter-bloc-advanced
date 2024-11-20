part of 'forgot_password_bloc.dart';

enum ForgotPasswordStatus { none, authenticating, authenticated, failure }

class ForgotPasswordState extends Equatable {
  final String email;
  final ForgotPasswordStatus status;

  static const String authenticationFailKey = 'error.authenticate';

  const ForgotPasswordState({
    this.email = '',
    this.status = ForgotPasswordStatus.none,
  });

  ForgotPasswordState copyWith({
    String? email,
    ForgotPasswordStatus? status,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [email, status];

  @override
  bool get stringify => true;
}

class AccountResetPasswordInitialState extends ForgotPasswordState {}

class AccountResetPasswordCompletedState extends ForgotPasswordState {}

class AccountResetPasswordErrorState extends ForgotPasswordState {
  final String message;

  const AccountResetPasswordErrorState({required this.message});
}
