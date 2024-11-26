import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

import '../../../../data/repository/account_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  static final _log = AppLogger.getLogger("ForgotPasswordBloc");
  final AccountRepository _repository;
  
  ForgotPasswordBloc({required AccountRepository repository})
      : _repository = repository,
        super(const ForgotPasswordState()) {
    on<ForgotPasswordEmailChanged>(_onSubmit);
  }


  @override
  void onTransition(Transition<ForgotPasswordEvent, ForgotPasswordState> transition) {
    super.onTransition(transition);
    _log.trace("current state: ${transition.currentState.toString()}");
    _log.trace("event: ${transition.event.toString()}");
    _log.trace("next state: ${transition.nextState.toString()}");
  }

  FutureOr<void> _onSubmit(ForgotPasswordEmailChanged event, Emitter<ForgotPasswordState> emit) async {
    _log.debug("BEGIN: forgotPassword bloc: _onSubmit");
    emit(AccountResetPasswordInitialState());
    try {
      String result = event.email.replaceAll('"', '');
      var resultStatusCode = await _repository.resetPassword(result);
      resultStatusCode < HttpStatus.badRequest
          ? emit(AccountResetPasswordCompletedState())
          : emit(const AccountResetPasswordErrorState(message: "Reset Password Error"));
      _log.debug("END: forgotPassword bloc: _onSubmit success: {}", [resultStatusCode.toString()]);
    } catch (e) {
      emit(const AccountResetPasswordErrorState(message: "Reset Password Error"));
      _log.error("END: forgotPassword bloc: _onSubmit error: {}", [e.toString()]);
    }
  }
}
