import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';

import '../../../../data/models/user_jwt.dart';
import '../../../../data/repository/login_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  static final _log = AppLogger.getLogger("LoginBloc");
  final LoginRepository _repository;

  LoginBloc({required LoginRepository repository})
      : _repository = repository,
        super(const LoginState()) {
    on<LoginFormSubmitted>(_onSubmit);
    on<TogglePasswordVisibility>((event, emit) => emit(state.copyWith(passwordVisible: !state.passwordVisible)));
  }

  @override
  void onTransition(Transition<LoginEvent, LoginState> transition) {
    super.onTransition(transition);
  }

  FutureOr<void> _onSubmit(LoginFormSubmitted event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onSubmit LoginFormSubmitted event: {}", [event.username]);
    emit(LoginLoadingState(username: event.username, password: event.password));

    UserJWT userJWT = UserJWT(state.username, state.password);
    try {
      if (event.username == "invalid") {
        throw BadRequestException("Invalid username");
      }
      // if(event.username.isEmpty || event.password.isEmpty) {
      //   throw BadRequestException("Username or password is empty");
      // }
      var token = await _repository.authenticate(userJWT);
      if (token != null && token.idToken != null) {
        await AppLocalStorage().save(StorageKeys.jwtToken.name, token.idToken);
        _log.debug("onSubmit save storage token: {}", [token.idToken]);
        await AppLocalStorage().save(StorageKeys.username.name, event.username);
        _log.debug("onSubmit save storage username: {}", [event.username]);
        emit(LoginLoadedState(username: event.username, password: event.password));
        _log.debug("END:onSubmit LoginFormSubmitted event success: {}", [token.toString()]);
      } else {
        throw BadRequestException("Invalid Access Token");
      }
    } catch (e) {
      emit(LoginErrorState(message: "Login API Error: ${e.toString()}"));
      _log.error("END:onSubmit LoginFormSubmitted event error: {}", [e.toString()]);
    }
  }
}
