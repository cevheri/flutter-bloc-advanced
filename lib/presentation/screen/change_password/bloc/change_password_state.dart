part of 'change_password_bloc.dart';

enum ChangePasswordStatus { none, authenticating, authenticated, failure }

class ChangePasswordState extends Equatable {
  final String email;
  final ChangePasswordStatus status;

  static const String authenticationFailKey = 'error.authenticate';

  const ChangePasswordState({
    this.email = '',
    this.status = ChangePasswordStatus.none,
  });

  ChangePasswordState copyWith({
    String? email,
    ChangePasswordStatus? status,
  }) {
    return ChangePasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [email, status];

  @override
  bool get stringify => true;
}

class ChangePasswordInitialState extends ChangePasswordState {}

class ChangePasswordPasswordCompletedState extends ChangePasswordState {}

class ChangePasswordPasswordErrorState extends ChangePasswordState {
  final String message;

  const ChangePasswordPasswordErrorState({required this.message});
}
