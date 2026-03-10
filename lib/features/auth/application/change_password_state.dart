part of 'change_password_bloc.dart';

enum ChangePasswordStatus { initial, loading, success, failure }

const String authenticationFailKey = 'error.authenticate';

class ChangePasswordState extends Equatable {
  final ChangePasswordStatus status;

  const ChangePasswordState({this.status = ChangePasswordStatus.initial});

  ChangePasswordState copyWith({ChangePasswordStatus? status}) {
    return ChangePasswordState(status: status ?? this.status);
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

class ChangePasswordCompletedState extends ChangePasswordState {
  const ChangePasswordCompletedState() : super(status: ChangePasswordStatus.success);
}

class ChangePasswordErrorState extends ChangePasswordState {
  final String message;

  const ChangePasswordErrorState({required this.message}) : super(status: ChangePasswordStatus.failure);

  @override
  List<Object> get props => [status, message];
}
