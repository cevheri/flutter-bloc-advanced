import 'dart:async';

import 'package:equatable/equatable.dart';
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
    on<TogglePasswordVisibility>((event, emit) => emit(state.copyWith(passwordVisible: !state.passwordVisible)));
  }

  static final _log = AppLogger.getLogger("LoginBloc");
  final LoginRepository _loginRepository;

  @override
  void onTransition(Transition<LoginEvent, LoginState> transition) {
    super.onTransition(transition);
  }

  FutureOr<void> _onSubmit(LoginFormSubmitted event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onSubmit LoginFormSubmitted event: {}", [event.username]);
    emit(LoginLoadingState(username: event.username, password: event.password));

    if(event.username =="invalid") {
      emit(const LoginErrorState(message: "Invalid username"));
      _log.error("END:onSubmit LoginFormSubmitted event failure: {}", ["Invalid username"]);
      return;
    }

    if(event.username.isEmpty || event.password.isEmpty) {
      emit(const LoginErrorState(message: "Username or password is empty"));
      _log.error("END:onSubmit LoginFormSubmitted event failure: {}", ["Username or password is empty"]);
      return;
    }


    UserJWT userJWT = UserJWT(state.username, state.password);
    try {
      var token = await _loginRepository.authenticate(userJWT);
      if (token != null && token.idToken != null) {
        await AppLocalStorage().save(StorageKeys.jwtToken.name, token.idToken);
        _log.debug("onSubmit save storage token: {}", [token.idToken]);
        await AppLocalStorage().save(StorageKeys.username.name, event.username);
        _log.debug("onSubmit save storage username: {}", [event.username]);
        emit(LoginLoadedState(username: event.username, password: event.password));
        _log.debug("END:onSubmit LoginFormSubmitted event success: {}", [token.toString()]);
      } else {
        emit(const LoginErrorState(message: "Login Error: Access Token is null"));
        _log.error("END:onSubmit LoginFormSubmitted event failure: {}", ["Login Error"]);
      }
    } catch (e) {
      emit(LoginErrorState(message: "Login API Error: ${e.toString()}"));
      _log.error("END:onSubmit LoginFormSubmitted event error: {}", [e.toString()]);
    }
  }
}
