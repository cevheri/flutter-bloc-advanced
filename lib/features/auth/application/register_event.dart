part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
}

class RegisterFormSubmitted extends RegisterEvent {
  final UserEntity data;

  const RegisterFormSubmitted({required this.data});

  @override
  List<Object> get props => [data];
}
