import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../data/http_utils.dart';
import '../../../../data/models/user_jwt.dart';
import '../../../../data/repository/login_repository.dart';

part 'login_event.dart';

part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required LoginRepository loginRepository})
      : _loginRepository = loginRepository,
        super(const LoginState()) {
    // on<LoginChanged>(_onLoginChange);
    // on<PasswordChanged>(_onPasswordChange);
    on<LoginFormSubmitted>(_onSubmit);
    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(passwordVisible: !state.passwordVisible));
    });
  }

  final LoginRepository _loginRepository;

  @override
  void onTransition(Transition<LoginEvent, LoginState> transition) {
    super.onTransition(transition);
  }

  FutureOr<void> _onSubmit(LoginFormSubmitted event, Emitter<LoginState> emit) async {
    log("LoginBloc.onSubmit start: ${event.username}, ${event.password}");
    emit(state.copyWith(
      username: event.username,
      password: event.password,
      status: LoginStatus.authenticating,
    ));
    UserJWT userJWT = UserJWT(state.username, state.password);
    try {
      var token = await _loginRepository.authenticate(userJWT);
      if (token.idToken != null) {
        log("LoginBloc.onSubmit token: ${token.idToken}");
        FlutterSecureStorage storage = FlutterSecureStorage();
        await storage.delete(key: HttpUtils.keyForJWTToken);
        await storage.write(key: HttpUtils.keyForJWTToken, value: token.idToken);
        emit(state.copyWith(status: LoginStatus.authenticated));
        log("LoginBloc.onSubmit end: ${state.status}");
      } else {
        emit(state.copyWith(status: LoginStatus.failure));
      }
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure));
      log("LoginBloc.onSubmit ERROR: ${e.toString()}");
    }
  }
}
