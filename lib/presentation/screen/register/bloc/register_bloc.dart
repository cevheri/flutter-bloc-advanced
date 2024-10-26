import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/models/user.dart';
import '../../../../data/repository/account_repository.dart';

part 'register_event.dart';

part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required AccountRepository AccountRepository})
      : _accountRepository = AccountRepository,
        super(const RegisterState()) {
    on<RegisterEmailChanged>(_onSubmit);
  }

  final AccountRepository _accountRepository;

  @override
  void onTransition(Transition<RegisterEvent, RegisterState> transition) {
    super.onTransition(transition);
  }

  FutureOr<void> _onSubmit(RegisterEmailChanged event, Emitter<RegisterState> emit) async {
    emit(RegisterInitialState());
    try {
      var resultStatusCode = await _accountRepository.register(event.createUset);
      resultStatusCode.statusCode == 201 ? emit(RegisterCompletedState()) : emit(const RegisterErrorState(message: "Reset Password Error"));
    } catch (e) {
      emit(const RegisterErrorState(message: "Reset Password Error"));
      rethrow;
    }
  }
}
