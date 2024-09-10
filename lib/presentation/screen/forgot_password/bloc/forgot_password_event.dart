part of 'forgot_password_bloc.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;
}

class TogglePasswordVisibility extends ForgotPasswordEvent {
  const TogglePasswordVisibility();
}

class ForgotPasswordEmailChanged extends ForgotPasswordEvent {
  final String email;

  const ForgotPasswordEmailChanged({
    required this.email,
  });
}
