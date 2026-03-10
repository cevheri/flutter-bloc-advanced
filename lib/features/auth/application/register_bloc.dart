import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/register_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  static final _log = AppLogger.getLogger("RegisterBloc");
  final RegisterAccountUseCase _registerAccountUseCase;

  RegisterBloc({
    RegisterAccountUseCase? registerAccountUseCase,
    IAccountRepository? repository,
  }) : _registerAccountUseCase = registerAccountUseCase ??
            RegisterAccountUseCase(repository ?? (throw ArgumentError('repository is required'))),
      super(const RegisterInitialState()) {
    on<RegisterFormSubmitted>(_onSubmit);
  }

  @override
  void onTransition(Transition<RegisterEvent, RegisterState> transition) {
    super.onTransition(transition);
    _log.trace("current state: ${transition.currentState.toString()}");
    _log.trace("event: ${transition.event.toString()}");
    _log.trace("next state: ${transition.nextState.toString()}");
  }

  FutureOr<void> _onSubmit(RegisterFormSubmitted event, Emitter<RegisterState> emit) async {
    _log.debug("BEGIN: onSubmit RegisterFormSubmitted event: {}", [event.data.toString()]);
    emit(const RegisterLoadingState());
    try {
      final user = await _registerAccountUseCase(event.data);
      if (user != null) {
        emit(RegisterCompletedState(user: user));
        _log.debug("END:onSubmit RegisterFormSubmitted event success: {}", [user.toString()]);
      } else {
        throw BadRequestException("Register Error: response is null");
      }
    } catch (e) {
      emit(RegisterErrorState(message: e.toString()));
      _log.error("END:onSubmit RegisterFormSubmitted event error: {}", [e.toString()]);
    }
  }
}
