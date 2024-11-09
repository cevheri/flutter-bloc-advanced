part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;
}

class TogglePasswordVisibility extends RegisterEvent {
  const TogglePasswordVisibility();
}

class RegisterEmailChanged extends RegisterEvent {
  final User createUser;

  const RegisterEmailChanged({
    required this.createUser,
  });
}
