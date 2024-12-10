part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
}

class RegisterFormSubmitted extends RegisterEvent {
  final User createUser;

  const RegisterFormSubmitted({
    required this.createUser,
  });

  @override
  List<Object> get props => [createUser];
}
