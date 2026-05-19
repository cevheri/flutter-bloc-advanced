import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/change_password_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  static final _log = AppLogger.getLogger("ChangePasswordBloc");
  final ChangePasswordUseCase _changePasswordUseCase;

  ChangePasswordBloc({required ChangePasswordUseCase changePasswordUseCase})
    : _changePasswordUseCase = changePasswordUseCase,
      super(const ChangePasswordState()) {
    on<ChangePasswordChanged>(_onSubmit);
  }

  FutureOr<void> _onSubmit(ChangePasswordChanged event, Emitter<ChangePasswordState> emit) async {
    _log.debug("BEGIN: changePassword bloc: _onSubmit");
    emit(const ChangePasswordState(status: ChangePasswordStatus.loading));

    if (event.currentPassword.isEmpty || event.newPassword.isEmpty) {
      emit(
        const ChangePasswordState(
          status: ChangePasswordStatus.failure,
          errorMessage: 'Both current and new password are required',
        ),
      );
      return;
    }

    if (event.currentPassword == event.newPassword) {
      emit(
        const ChangePasswordState(
          status: ChangePasswordStatus.failure,
          errorMessage: 'New password must be different from current password',
        ),
      );
      return;
    }

    final passwordChangeDTO = PasswordChangeDTO(currentPassword: event.currentPassword, newPassword: event.newPassword);

    final result = await _changePasswordUseCase(passwordChangeDTO);
    switch (result) {
      case Success():
        emit(const ChangePasswordState(status: ChangePasswordStatus.success));
        _log.debug("END: changePassword bloc: _onSubmit success");
      case Failure(:final error):
        emit(ChangePasswordState(status: ChangePasswordStatus.failure, errorMessage: error.message));
        _log.error("END: changePassword bloc: _onSubmit error: {}", [error.toString()]);
    }
  }
}
