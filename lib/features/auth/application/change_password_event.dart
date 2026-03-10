part of 'change_password_bloc.dart';

abstract class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;
}

class TogglePasswordVisibility extends ChangePasswordEvent {
  const TogglePasswordVisibility();
}

class ChangePasswordChanged extends ChangePasswordEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordChanged({required this.currentPassword, required this.newPassword});
}
