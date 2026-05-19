part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();
}

final class ForgotPasswordInitialState extends ForgotPasswordState {
  const ForgotPasswordInitialState();

  @override
  List<Object?> get props => const [];
}

final class ForgotPasswordLoadingState extends ForgotPasswordState {
  const ForgotPasswordLoadingState();

  @override
  List<Object?> get props => const [];
}

final class ForgotPasswordCompletedState extends ForgotPasswordState {
  const ForgotPasswordCompletedState({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

final class ForgotPasswordErrorState extends ForgotPasswordState {
  const ForgotPasswordErrorState({required this.email, required this.errorMessage});

  final String email;
  final String errorMessage;

  @override
  List<Object?> get props => [email, errorMessage];
}
