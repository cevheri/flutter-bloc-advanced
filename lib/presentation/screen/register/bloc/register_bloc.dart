import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/user.dart';
import '../../../../data/repository/account_repository.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required AccountRepository accountRepository})
      : _accountRepository = accountRepository,
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
      await _accountRepository.register(event.createUser);
      emit(RegisterCompletedState());
    } catch (e) {
      emit(const RegisterErrorState(message: "Register Error"));
      rethrow;
    }
  }
}
