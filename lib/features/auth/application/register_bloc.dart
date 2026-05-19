import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/register_account_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  static final _log = AppLogger.getLogger("RegisterBloc");
  final RegisterAccountUseCase _registerAccountUseCase;

  RegisterBloc({required RegisterAccountUseCase registerAccountUseCase})
    : _registerAccountUseCase = registerAccountUseCase,
      super(const RegisterInitialState()) {
    on<RegisterFormSubmitted>(_onSubmit, transformer: EventTransformers.dropConcurrent());
  }

  FutureOr<void> _onSubmit(RegisterFormSubmitted event, Emitter<RegisterState> emit) async {
    _log.debug('BEGIN: onSubmit RegisterFormSubmitted login={}', [event.data.login]);
    emit(const RegisterLoadingState());

    final result = await _registerAccountUseCase(event.data);
    switch (result) {
      case Success(:final data):
        emit(RegisterCompletedState(user: data));
        _log.debug("END:onSubmit RegisterFormSubmitted event success: {}", [data.toString()]);
      case Failure(:final error):
        emit(RegisterErrorState(message: error.message));
        _log.error("END:onSubmit RegisterFormSubmitted event error: {}", [error.toString()]);
    }
  }
}
