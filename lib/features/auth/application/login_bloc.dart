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
       super(const LoginInitialState()) {
    on<LoginFormSubmitted>(_onSubmit);
    on<TogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<ChangeLoginMethod>(_onChangeLoginMethod);
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
  }

  /// Recreate the current variant with a flipped `passwordVisible`, preserving
  /// its type and other carried fields. Plain `copyWith` cannot do this under
  /// sealed semantics — that was the original #70 bug.
  void _onTogglePasswordVisibility(TogglePasswordVisibility event, Emitter<LoginState> emit) {
    final v = !state.passwordVisible;
    final m = state.loginMethod;
    emit(switch (state) {
      LoginInitialState() => LoginInitialState(loginMethod: m, passwordVisible: v),
      LoginLoadingState(:final username) => LoginLoadingState(username: username, loginMethod: m, passwordVisible: v),
      LoginLoadedState(:final username) => LoginLoadedState(username: username, loginMethod: m, passwordVisible: v),
      LoginOtpSentState(:final email) => LoginOtpSentState(email: email, passwordVisible: v),
      LoginOtpVerifiedState(:final email, :final otpCode) => LoginOtpVerifiedState(
        email: email,
        otpCode: otpCode,
        passwordVisible: v,
      ),
      LoginErrorState(:final message) => LoginErrorState(message: message, loginMethod: m, passwordVisible: v),
    });
  }

  FutureOr<void> _onSubmit(LoginFormSubmitted event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onSubmit LoginFormSubmitted event: {}", [event.username]);
    emit(
      LoginLoadingState(
        username: event.username,
        loginMethod: state.loginMethod,
        passwordVisible: state.passwordVisible,
      ),
    );

    if (event.username == "invalid") {
      emit(
        LoginErrorState(
          message: "Login API Error: Invalid username",
          loginMethod: state.loginMethod,
          passwordVisible: state.passwordVisible,
        ),
      );
      _log.error("END:onSubmit LoginFormSubmitted event error: Invalid username");
      return;
    }

    final credentials = AuthCredentialsEntity(username: event.username, password: event.password);
    final tokenResult = await _authenticateUserUseCase(credentials);
    switch (tokenResult) {
      case Success(:final data):
        if (!data.isValid) {
          emit(
            LoginErrorState(
              message: "Login API Error: Invalid Access Token",
              loginMethod: state.loginMethod,
              passwordVisible: state.passwordVisible,
            ),
          );
          return;
        }
        await AppLocalStorage().save(StorageKeys.jwtToken.key, data.idToken);
        _log.debug("onSubmit save storage token: {}", [data.idToken]);
        if (data.refreshToken != null) {
          await AppLocalStorage().save(StorageKeys.refreshToken.key, data.refreshToken);
          _log.debug("onSubmit save storage refreshToken");
        }
        await AppLocalStorage().save(StorageKeys.username.key, event.username);
        _log.debug("onSubmit save storage username: {}", [event.username]);
        final accountResult = await _getAccountUseCase();
        switch (accountResult) {
          case Success(data: final user):
            await AppLocalStorage().save(StorageKeys.roles.key, user.authorities);
            _log.debug("onSubmit save storage roles: {}", [user.authorities]);
            emit(
              LoginLoadedState(
                username: event.username,
                loginMethod: state.loginMethod,
                passwordVisible: state.passwordVisible,
              ),
            );
            _log.debug("END:onSubmit LoginFormSubmitted event success: {}", [data.toString()]);
          case Failure(:final error):
            emit(
              LoginErrorState(
                message: "Login API Error: ${error.message}",
                loginMethod: state.loginMethod,
                passwordVisible: state.passwordVisible,
              ),
            );
            _log.error("END:onSubmit getAccount error: {}", [error.toString()]);
        }
      case Failure(:final error):
        emit(
          LoginErrorState(
            message: "Login API Error: ${error.message}",
            loginMethod: state.loginMethod,
            passwordVisible: state.passwordVisible,
          ),
        );
        _log.error("END:onSubmit LoginFormSubmitted event error: {}", [error.message]);
    }
  }

  void _onChangeLoginMethod(ChangeLoginMethod event, Emitter<LoginState> emit) {
    emit(LoginInitialState(loginMethod: event.method, passwordVisible: state.passwordVisible));
  }

  Future<void> _onSendOtpRequested(SendOtpRequested event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onSendOtpRequested SendOtpRequested event: {}", [event.email]);
    emit(
      LoginLoadingState(username: event.email, loginMethod: LoginMethod.otp, passwordVisible: state.passwordVisible),
    );
    final result = await _sendOtpUseCase(SendOtpEntity(email: event.email));
    switch (result) {
      case Success():
        emit(LoginOtpSentState(email: event.email, passwordVisible: state.passwordVisible));
        _log.debug("END: onSendOtpRequested SendOtpRequested event success: {}", [event.email]);
      case Failure(:final error):
        emit(
          LoginErrorState(
            message: "Send OTP error: ${error.message}",
            loginMethod: LoginMethod.otp,
            passwordVisible: state.passwordVisible,
          ),
        );
        _log.error("END: onSendOtpRequested SendOtpRequested event error: {}", [error.message]);
    }
  }

  Future<void> _onVerifyOtpSubmitted(VerifyOtpSubmitted event, Emitter<LoginState> emit) async {
    _log.debug("BEGIN: onVerifyOtpSubmitted VerifyOtpSubmitted event: {}", [event.email]);
    emit(
      LoginLoadingState(username: event.email, loginMethod: LoginMethod.otp, passwordVisible: state.passwordVisible),
    );
    final tokenResult = await _verifyOtpUseCase(VerifyOtpEntity(email: event.email, otp: event.otpCode));
    switch (tokenResult) {
      case Success(:final data):
        _log.debug("onVerifyOtpSubmitted token: {}", [data.toString()]);
        if (!data.isValid) {
          emit(
            LoginErrorState(
              message: "OTP validation error",
              loginMethod: LoginMethod.otp,
              passwordVisible: state.passwordVisible,
            ),
          );
          return;
        }
        await AppLocalStorage().save(StorageKeys.jwtToken.key, data.idToken);
        if (data.refreshToken != null) {
          await AppLocalStorage().save(StorageKeys.refreshToken.key, data.refreshToken);
        }
        await AppLocalStorage().save(StorageKeys.username.key, event.email);
        final accountResult = await _getAccountUseCase();
        switch (accountResult) {
          case Success(data: final user):
            await AppLocalStorage().save(StorageKeys.roles.key, user.authorities);
            emit(
              LoginLoadedState(
                username: event.email,
                loginMethod: LoginMethod.otp,
                passwordVisible: state.passwordVisible,
              ),
            );
          case Failure():
            emit(
              LoginErrorState(
                message: "OTP validation error",
                loginMethod: LoginMethod.otp,
                passwordVisible: state.passwordVisible,
              ),
            );
        }
      case Failure(:final error):
        emit(
          LoginErrorState(
            message: "OTP validation error",
            loginMethod: LoginMethod.otp,
            passwordVisible: state.passwordVisible,
          ),
        );
        _log.error("END: onVerifyOtpSubmitted error: {}", [error.message]);
    }
  }
}
