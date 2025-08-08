import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

import '../../../../data/models/change_password.dart';
import '../../../../data/repository/account_repository.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  static final _log = AppLogger.getLogger("ChangePasswordBloc");
  final AccountRepository _repository;

  ChangePasswordBloc({required AccountRepository repository})
    : _repository = repository,
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

    try {
      if (event.currentPassword.isEmpty || event.newPassword.isEmpty) {
        emit(state.copyWith(status: ChangePasswordStatus.failure));
        return;
      }

      if (event.currentPassword == event.newPassword) {
        emit(state.copyWith(status: ChangePasswordStatus.failure));
        return;
      }

      PasswordChangeDTO passwordChangeDTO = PasswordChangeDTO(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      final result = await _repository.changePassword(passwordChangeDTO);

      emit(
        state.copyWith(
          status: result < HttpStatus.badRequest ? ChangePasswordStatus.success : ChangePasswordStatus.failure,
        ),
      );

      _log.debug("END: changePassword bloc: _onSubmit success: {}", [result.toString()]);
    } catch (e) {
      emit(state.copyWith(status: ChangePasswordStatus.failure));
      _log.error("END: changePassword bloc: _onSubmit error: {}", [e.toString()]);
    }
  }
}
