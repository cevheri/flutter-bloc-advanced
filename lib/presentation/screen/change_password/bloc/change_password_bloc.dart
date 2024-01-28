import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/models/change_password.dart';
import '../../../../data/repository/account_repository.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc({required AccountRepository AccountRepository})
      : _AccountRepository = AccountRepository,
        super(const ChangePasswordState()) {
    on<ChangePasswordChanged>(_onSubmit);
  }

  final AccountRepository _AccountRepository;

  @override
  void onTransition(Transition<ChangePasswordEvent, ChangePasswordState> transition) {
    super.onTransition(transition);
  }

  FutureOr<void> _onSubmit(ChangePasswordChanged event, Emitter<ChangePasswordState> emit) async {
    emit(ChangePasswordInitialState());
    try {
      PasswordChangeDTO passwordChangeDTO = PasswordChangeDTO(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      var result = await _AccountRepository.changePassword(passwordChangeDTO);
      result == 200 ? emit(ChangePasswordPasswordCompletedState()) : emit(const ChangePasswordPasswordErrorState(message: "Reset Password Error"));
    } catch (e) {
      emit(const ChangePasswordPasswordErrorState(message: "Reset Password Error"));
      rethrow;
    }
  }
}
