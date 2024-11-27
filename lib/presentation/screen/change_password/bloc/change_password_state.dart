part of 'change_password_bloc.dart';

enum ChangePasswordStatus { initial, loading, success, failure }

class ChangePasswordState extends Equatable {
  final ChangePasswordStatus status;

  static const String authenticationFailKey = 'error.authenticate';

  const ChangePasswordState({
    this.status = ChangePasswordStatus.initial,
  });

  ChangePasswordState copyWith({
    String? email,
    ChangePasswordStatus? status,
  }) {
    return ChangePasswordState(
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [status];

  @override
  bool get stringify => true;
}

class ChangePasswordInitialState extends ChangePasswordState {
  const ChangePasswordInitialState() : super(status: ChangePasswordStatus.initial);
}

class ChangePasswordLoadingState extends ChangePasswordState {
  const ChangePasswordLoadingState() : super(status: ChangePasswordStatus.loading);
}

class ChangePasswordPasswordCompletedState extends ChangePasswordState {
  const ChangePasswordPasswordCompletedState() : super(status: ChangePasswordStatus.success);
}

class ChangePasswordPasswordErrorState extends ChangePasswordState {
  final String message;

  const ChangePasswordPasswordErrorState({required this.message}) : super(status: ChangePasswordStatus.failure);

  @override
  List<Object> get props => [status, message];
}
