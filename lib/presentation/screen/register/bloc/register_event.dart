part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
}

class RegisterFormSubmitted extends RegisterEvent {
  final User data;

  const RegisterFormSubmitted({required this.data});

  @override
  List<Object> get props => [data];
}
