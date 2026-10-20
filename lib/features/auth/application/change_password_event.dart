part of 'change_password_bloc.dart';

abstract class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object> get props => [];
}

class ChangePasswordChanged extends ChangePasswordEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordChanged({required this.currentPassword, required this.newPassword});

  @override
  List<Object> get props => [currentPassword, newPassword];

  /// Both passwords are masked: the debug observer records the text of every event in the dev console.
  @override
  String toString() => 'ChangePasswordChanged(currentPassword: $secretMask, newPassword: $secretMask)';
}
