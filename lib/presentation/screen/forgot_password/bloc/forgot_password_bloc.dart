import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../../../../data/repository/account_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  static final _log = AppLogger.getLogger("ForgotPasswordBloc");
  final AccountRepository _repository;

  ForgotPasswordBloc({required AccountRepository repository})
    : _repository = repository,
      super(const ForgotPasswordState(status: ForgotPasswordStatus.initial)) {
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
    emit(state.copyWith(status: ForgotPasswordStatus.loading));
    try {
      String result = event.email.replaceAll('"', '');
      var resultStatusCode = await _repository.resetPassword(result);
      if (resultStatusCode < HttpStatus.badRequest) {
        emit(state.copyWith(status: ForgotPasswordStatus.success, email: result));
      } else {
        throw BadRequestException("API Error");
      }
      _log.debug("END: forgotPassword bloc: _onSubmit success: {}", [resultStatusCode.toString()]);
    } catch (e) {
      emit(state.copyWith(status: ForgotPasswordStatus.failure));
      _log.error("END: forgotPassword bloc: _onSubmit error: {}", [e.toString()]);
    }
  }
}
