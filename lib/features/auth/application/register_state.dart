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
  const RegisterErrorState({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
