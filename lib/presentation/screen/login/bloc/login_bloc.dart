import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';

import '../../../../data/models/user_jwt.dart';
import '../../../../data/repository/login_repository.dart';

part 'login_event.dart';

part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required LoginRepository loginRepository})
      : _loginRepository = loginRepository,
        super(const LoginState()) {
    on<LoginFormSubmitted>(_onSubmit);
    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(passwordVisible: !state.passwordVisible));
    });
  }

  static final _log = AppLogger.getLogger("LoginBloc");
  final LoginRepository _loginRepository;

  @override
  void onTransition(Transition<LoginEvent, LoginState> transition) {
    super.onTransition(transition);
  }

  FutureOr<void> _onSubmit(LoginFormSubmitted event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onSubmit LoginFormSubmitted event: {}", [event.username]);
    emit(state.copyWith(
      username: event.username,
      password: event.password,
      status: LoginStatus.authenticating,
    ));
    UserJWT userJWT = UserJWT(state.username, state.password);
    try {
      var token = await _loginRepository.authenticate(userJWT);
      if (token != null && token.idToken != null) {
        await AppLocalStorage().save(StorageKeys.jwtToken.name, token.idToken);
        _log.debug("onSubmit save storage token: {}", [token.idToken]);
        await AppLocalStorage().save(StorageKeys.username.name, event.username);
        _log.debug("onSubmit save storage username: {}", [event.username]);

        emit(state.copyWith(status: LoginStatus.authenticated));
        emit(LoginLoadedState());
        _log.debug("END:onSubmit LoginFormSubmitted event success: {}", [token.toString()]);
      } else {
        emit(state.copyWith(status: LoginStatus.failure));
        emit(const LoginErrorState(message: "Login Error"));
        _log.error("END:onSubmit LoginFormSubmitted event failure: {}", ["Login Error"]);
      }
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure));
      emit(const LoginErrorState(message: "Login Error"));
      debugPrint(e.toString(), wrapWidth: 1024);
      _log.error("END:onSubmit LoginFormSubmitted event error: {}", [e.toString()]);
    }
  }
}
