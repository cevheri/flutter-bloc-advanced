part of 'change_password_bloc.dart';

sealed class ChangePasswordState extends Equatable {
  const ChangePasswordState();
}

final class ChangePasswordInitialState extends ChangePasswordState {
  const ChangePasswordInitialState();

  @override
  List<Object?> get props => const [];
}

final class ChangePasswordLoadingState extends ChangePasswordState {
  const ChangePasswordLoadingState();

  @override
  List<Object?> get props => const [];
}

final class ChangePasswordSuccessState extends ChangePasswordState {
  const ChangePasswordSuccessState();

  @override
  List<Object?> get props => const [];
}

/// Changing the password failed. The UI shows [errorCode] translated via `errorCode.resolve(context)`; the raw
/// error message only goes to the log.
final class ChangePasswordFailureState extends ChangePasswordState {
  const ChangePasswordFailureState({required this.errorCode});

  final AppErrorCode errorCode;

  @override
  List<Object?> get props => [errorCode];
}
