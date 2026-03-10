import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/reset_password_usecase.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  static final _log = AppLogger.getLogger("ForgotPasswordBloc");
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordBloc({
    ResetPasswordUseCase? resetPasswordUseCase,
    IAccountRepository? repository,
  }) : _resetPasswordUseCase = resetPasswordUseCase ??
            ResetPasswordUseCase(repository ?? (throw ArgumentError('repository is required'))),
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
      final result = event.email.replaceAll('"', '');
      final resultStatusCode = await _resetPasswordUseCase(result);
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
