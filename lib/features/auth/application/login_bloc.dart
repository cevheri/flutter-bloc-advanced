import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';

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

    final credentials = AuthCredentialsEntity(username: event.username, password: event.password);
    try {
      if (event.username == "invalid") {
        throw BadRequestException("Invalid username");
      }
      final token = await _authenticateUserUseCase(credentials);
      if (token != null && token.isValid) {
        await AppLocalStorage().save(StorageKeys.jwtToken.name, token.idToken);
        _log.debug("onSubmit save storage token: {}", [token.idToken]);
        await AppLocalStorage().save(StorageKeys.username.name, event.username);
        _log.debug("onSubmit save storage username: {}", [event.username]);
        final user = await _getAccountUseCase();
        await AppLocalStorage().save(StorageKeys.roles.name, user.authorities);
        _log.debug("onSubmit save storage roles: {}", [user.authorities]);

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

  void _onChangeLoginMethod(ChangeLoginMethod event, Emitter<LoginState> emit) {
    emit(state.copyWith(loginMethod: event.method, status: LoginStatus.initial, isOtpSent: false));
  }

  Future<void> _onSendOtpRequested(SendOtpRequested event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onSendOtpRequested SendOtpRequested event: {}", [event.email]);
    emit(LoginLoadingState(username: event.email));
    try {
      await _sendOtpUseCase(SendOtpEntity(email: event.email));
      emit(LoginOtpSentState(email: event.email));
      _log.debug("END: onSendOtpRequested SendOtpRequested event success: {}", [event.email]);
    } catch (e) {
      emit(LoginErrorState(message: "Send OTP error: ${e.toString()}"));
      _log.error("END: onSendOtpRequested SendOtpRequested event error: {}", [e.toString()]);
    }
  }

  Future<void> _onVerifyOtpSubmitted(VerifyOtpSubmitted event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onVerifyOtpSubmitted VerifyOtpSubmitted event: {}", [event.email]);
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final token = await _verifyOtpUseCase(VerifyOtpEntity(email: event.email, otp: event.otpCode));
      _log.debug("onVerifyOtpSubmitted token: {}", [token.toString()]);
      if (token != null && token.isValid) {
        await AppLocalStorage().save(StorageKeys.jwtToken.name, token.idToken);
        await AppLocalStorage().save(StorageKeys.username.name, event.email);

        final user = await _getAccountUseCase();
        await AppLocalStorage().save(StorageKeys.roles.name, user.authorities);

        emit(LoginLoadedState(username: event.email, password: event.otpCode));
      } else {
        throw BadRequestException("Invalid OTP Token");
      }
    } catch (e) {
      emit(const LoginErrorState(message: "OTP validation error"));
    }
  }
}
