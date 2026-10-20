part of 'register_bloc.dart';

sealed class RegisterState extends Equatable {
  const RegisterState();
}

final class RegisterInitialState extends RegisterState {
  const RegisterInitialState();

  @override
  List<Object?> get props => const [];
}

final class RegisterLoadingState extends RegisterState {
  const RegisterLoadingState();

  @override
  List<Object?> get props => const [];
}

final class RegisterCompletedState extends RegisterState {
  const RegisterCompletedState({required this.user});

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

final class RegisterErrorState extends RegisterState {
  const RegisterErrorState({required this.message, this.errorCode});

  final String message;

  /// Set when the failure has a translated message, which the UI shows via `errorCode.resolve(context)` instead of
  /// its generic one.
  final AppErrorCode? errorCode;

  @override
  List<Object?> get props => [message, errorCode];
}
