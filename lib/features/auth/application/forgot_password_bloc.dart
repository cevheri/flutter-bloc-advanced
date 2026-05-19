import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/reset_password_usecase.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  static final _log = AppLogger.getLogger("ForgotPasswordBloc");
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordBloc({required ResetPasswordUseCase resetPasswordUseCase})
    : _resetPasswordUseCase = resetPasswordUseCase,
      super(const ForgotPasswordInitialState()) {
    on<ForgotPasswordEmailChanged>(_onSubmit, transformer: EventTransformers.dropConcurrent());
  }

  FutureOr<void> _onSubmit(ForgotPasswordEmailChanged event, Emitter<ForgotPasswordState> emit) async {
    _log.debug("BEGIN: forgotPassword bloc: _onSubmit");
    emit(const ForgotPasswordLoadingState());

    final result = await _resetPasswordUseCase(event.email);
    switch (result) {
      case Success():
        emit(ForgotPasswordCompletedState(email: event.email));
        _log.debug("END: forgotPassword bloc: _onSubmit success");
      case Failure(:final error):
        emit(ForgotPasswordErrorState(email: event.email, errorMessage: error.message));
        _log.error("END: forgotPassword bloc: _onSubmit error: {}", [error.toString()]);
    }
  }
}
