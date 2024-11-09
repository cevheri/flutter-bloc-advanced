import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repository/account_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({required AccountRepository accountRepository})
      : _accountRepository = accountRepository,
        super(const ForgotPasswordState()) {
    on<ForgotPasswordEmailChanged>(_onSubmit);
  }

  final AccountRepository _accountRepository;

  @override
  void onTransition(Transition<ForgotPasswordEvent, ForgotPasswordState> transition) {
    super.onTransition(transition);
  }

  FutureOr<void> _onSubmit(ForgotPasswordEmailChanged event, Emitter<ForgotPasswordState> emit) async {
    emit(AccountResetPasswordInitialState());
    try {
      String result = event.email.replaceAll('"', '');
      var resultStatusCode = await _accountRepository.resetPassword(result);
      resultStatusCode == 200
          ? emit(AccountResetPasswordCompletedState())
          : emit(const AccountResetPasswordErrorState(message: "Reset Password Error"));
    } catch (e) {
      emit(const AccountResetPasswordErrorState(message: "Reset Password Error"));
      rethrow;
    }
  }
}
