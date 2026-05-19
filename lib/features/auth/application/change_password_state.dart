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

final class ChangePasswordFailureState extends ChangePasswordState {
  const ChangePasswordFailureState({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
