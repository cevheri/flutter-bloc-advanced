import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/change_password_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  static final _log = AppLogger.getLogger("ChangePasswordBloc");
  final ChangePasswordUseCase _changePasswordUseCase;

  ChangePasswordBloc({ChangePasswordUseCase? changePasswordUseCase, IAccountRepository? repository})
    : _changePasswordUseCase =
          changePasswordUseCase ?? ChangePasswordUseCase(repository ?? (throw ArgumentError('repository is required'))),
      super(const ChangePasswordState()) {
    on<ChangePasswordChanged>(_onSubmit);
  }

  @override
  void onTransition(Transition<ChangePasswordEvent, ChangePasswordState> transition) {
    super.onTransition(transition);
    _log.trace("current state: ${transition.currentState.toString()}");
    _log.trace("event: ${transition.event.toString()}");
    _log.trace("next state: ${transition.nextState.toString()}");
  }

  FutureOr<void> _onSubmit(ChangePasswordChanged event, Emitter<ChangePasswordState> emit) async {
    _log.debug("BEGIN: changePassword bloc: _onSubmit");
    emit(state.copyWith(status: ChangePasswordStatus.loading));

    if (event.currentPassword.isEmpty || event.newPassword.isEmpty) {
      emit(state.copyWith(status: ChangePasswordStatus.failure));
      return;
    }

    if (event.currentPassword == event.newPassword) {
      emit(state.copyWith(status: ChangePasswordStatus.failure));
      return;
    }

    final passwordChangeDTO = PasswordChangeDTO(currentPassword: event.currentPassword, newPassword: event.newPassword);

    final result = await _changePasswordUseCase(passwordChangeDTO);
    switch (result) {
      case Success():
        emit(state.copyWith(status: ChangePasswordStatus.success));
        _log.debug("END: changePassword bloc: _onSubmit success");
      case Failure(:final error):
        emit(state.copyWith(status: ChangePasswordStatus.failure));
        _log.error("END: changePassword bloc: _onSubmit error: {}", [error.toString()]);
    }
  }
}
