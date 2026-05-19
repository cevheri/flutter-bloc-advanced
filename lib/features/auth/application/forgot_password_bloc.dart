import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/reset_password_usecase.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  static final _log = AppLogger.getLogger("ForgotPasswordBloc");
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordBloc({required ResetPasswordUseCase resetPasswordUseCase})
    : _resetPasswordUseCase = resetPasswordUseCase,
      super(const ForgotPasswordState(status: ForgotPasswordStatus.initial)) {
    on<ForgotPasswordEmailChanged>(_onSubmit);
  }

  FutureOr<void> _onSubmit(ForgotPasswordEmailChanged event, Emitter<ForgotPasswordState> emit) async {
    _log.debug("BEGIN: forgotPassword bloc: _onSubmit");
    emit(const ForgotPasswordState(status: ForgotPasswordStatus.loading));

    final result = await _resetPasswordUseCase(event.email);
    switch (result) {
      case Success():
        emit(ForgotPasswordState(status: ForgotPasswordStatus.success, email: event.email));
        _log.debug("END: forgotPassword bloc: _onSubmit success");
      case Failure(:final error):
        emit(
          ForgotPasswordState(status: ForgotPasswordStatus.failure, email: event.email, errorMessage: error.message),
        );
        _log.error("END: forgotPassword bloc: _onSubmit error: {}", [error.toString()]);
    }
  }
}
