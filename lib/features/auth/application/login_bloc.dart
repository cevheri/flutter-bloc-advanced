import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  static final _log = AppLogger.getLogger("LoginBloc");
  final AuthenticateUserUseCase _authenticateUserUseCase;
  final SendOtpUseCase _sendOtpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final GetAccountUseCase _getAccountUseCase;

  LoginBloc({
    required AuthenticateUserUseCase authenticateUserUseCase,
    required SendOtpUseCase sendOtpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required GetAccountUseCase getAccountUseCase,
  }) : _authenticateUserUseCase = authenticateUserUseCase,
       _sendOtpUseCase = sendOtpUseCase,
       _verifyOtpUseCase = verifyOtpUseCase,
       _getAccountUseCase = getAccountUseCase,
       super(const LoginState()) {
    on<LoginFormSubmitted>(_onSubmit);
    on<TogglePasswordVisibility>((event, emit) => emit(state.copyWith(passwordVisible: !state.passwordVisible)));
    on<ChangeLoginMethod>(_onChangeLoginMethod);
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
  }

  @override
  void onTransition(Transition<LoginEvent, LoginState> transition) {
    super.onTransition(transition);
  }

  FutureOr<void> _onSubmit(LoginFormSubmitted event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onSubmit LoginFormSubmitted event: {}", [event.username]);
    emit(LoginLoadingState(username: event.username, password: event.password));

    if (event.username == "invalid") {
      emit(const LoginErrorState(message: "Login API Error: Invalid username"));
      _log.error("END:onSubmit LoginFormSubmitted event error: Invalid username");
      return;
    }

    final credentials = AuthCredentialsEntity(username: event.username, password: event.password);
    final tokenResult = await _authenticateUserUseCase(credentials);
    switch (tokenResult) {
      case Success(:final data):
        if (!data.isValid) {
          emit(const LoginErrorState(message: "Login API Error: Invalid Access Token"));
          return;
        }
        await AppLocalStorage().save(StorageKeys.jwtToken.name, data.idToken);
        _log.debug("onSubmit save storage token: {}", [data.idToken]);
        await AppLocalStorage().save(StorageKeys.username.name, event.username);
        _log.debug("onSubmit save storage username: {}", [event.username]);
        final accountResult = await _getAccountUseCase();
        switch (accountResult) {
          case Success(data: final user):
            await AppLocalStorage().save(StorageKeys.roles.name, user.authorities);
            _log.debug("onSubmit save storage roles: {}", [user.authorities]);
            emit(LoginLoadedState(username: event.username, password: event.password));
            _log.debug("END:onSubmit LoginFormSubmitted event success: {}", [data.toString()]);
          case Failure(:final error):
            emit(LoginErrorState(message: "Login API Error: ${error.message}"));
            _log.error("END:onSubmit getAccount error: {}", [error.toString()]);
        }
      case Failure(:final error):
        emit(LoginErrorState(message: "Login API Error: ${error.message}"));
        _log.error("END:onSubmit LoginFormSubmitted event error: {}", [error.message]);
    }
  }

  void _onChangeLoginMethod(ChangeLoginMethod event, Emitter<LoginState> emit) {
    emit(state.copyWith(loginMethod: event.method, status: LoginStatus.initial, isOtpSent: false));
  }

  Future<void> _onSendOtpRequested(SendOtpRequested event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onSendOtpRequested SendOtpRequested event: {}", [event.email]);
    emit(LoginLoadingState(username: event.email));
    final result = await _sendOtpUseCase(SendOtpEntity(email: event.email));
    switch (result) {
      case Success():
        emit(LoginOtpSentState(email: event.email));
        _log.debug("END: onSendOtpRequested SendOtpRequested event success: {}", [event.email]);
      case Failure(:final error):
        emit(LoginErrorState(message: "Send OTP error: ${error.message}"));
        _log.error("END: onSendOtpRequested SendOtpRequested event error: {}", [error.message]);
    }
  }

  Future<void> _onVerifyOtpSubmitted(VerifyOtpSubmitted event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onVerifyOtpSubmitted VerifyOtpSubmitted event: {}", [event.email]);
    emit(state.copyWith(status: LoginStatus.loading));
    final tokenResult = await _verifyOtpUseCase(VerifyOtpEntity(email: event.email, otp: event.otpCode));
    switch (tokenResult) {
      case Success(:final data):
        _log.debug("onVerifyOtpSubmitted token: {}", [data.toString()]);
        if (!data.isValid) {
          emit(const LoginErrorState(message: "OTP validation error"));
          return;
        }
        await AppLocalStorage().save(StorageKeys.jwtToken.name, data.idToken);
        await AppLocalStorage().save(StorageKeys.username.name, event.email);
        final accountResult = await _getAccountUseCase();
        switch (accountResult) {
          case Success(data: final user):
            await AppLocalStorage().save(StorageKeys.roles.name, user.authorities);
            emit(LoginLoadedState(username: event.email, password: event.otpCode));
          case Failure():
            emit(const LoginErrorState(message: "OTP validation error"));
        }
      case Failure(:final error):
        emit(const LoginErrorState(message: "OTP validation error"));
        _log.error("END: onVerifyOtpSubmitted error: {}", [error.message]);
    }
  }
}
