import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/persist_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  static final _log = AppLogger.getLogger("LoginBloc");
  final AuthenticateUserUseCase _authenticateUserUseCase;
  final SendOtpUseCase _sendOtpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final GetAccountUseCase _getAccountUseCase;
  final PersistAuthSessionUseCase _persistAuthSessionUseCase;

  LoginBloc({
    required AuthenticateUserUseCase authenticateUserUseCase,
    required SendOtpUseCase sendOtpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required GetAccountUseCase getAccountUseCase,
    required PersistAuthSessionUseCase persistAuthSessionUseCase,
  }) : _authenticateUserUseCase = authenticateUserUseCase,
       _sendOtpUseCase = sendOtpUseCase,
       _verifyOtpUseCase = verifyOtpUseCase,
       _getAccountUseCase = getAccountUseCase,
       _persistAuthSessionUseCase = persistAuthSessionUseCase,
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
        await _completeLogin(token: data, username: event.username, loginMethod: state.loginMethod, emit: emit);
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
        await _completeLogin(
          token: data,
          username: event.email,
          loginMethod: LoginMethod.otp,
          emit: emit,
          errorMessage: "OTP validation error",
        );
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

  /// Persist the session and resolve the account in one place, used by
  /// both the password and OTP success paths. Storage writes go through
  /// [PersistAuthSessionUseCase] — the bloc itself never imports
  /// `infrastructure/storage` (fixes #71).
  Future<void> _completeLogin({
    required AuthTokenEntity token,
    required String username,
    required LoginMethod loginMethod,
    required Emitter<LoginState> emit,
    String? errorMessage,
  }) async {
    final accountResult = await _getAccountUseCase();
    switch (accountResult) {
      case Success(data: final user):
        final session = AuthSession(
          idToken: token.idToken,
          refreshToken: token.refreshToken,
          username: username,
          roles: user.authorities ?? const [],
        );
        final persistResult = await _persistAuthSessionUseCase(session);
        switch (persistResult) {
          case Success():
            emit(
              LoginLoadedState(username: username, loginMethod: loginMethod, passwordVisible: state.passwordVisible),
            );
            _log.debug("session persisted for: {}", [username]);
          case Failure(:final error):
            emit(
              LoginErrorState(
                message: errorMessage ?? "Login API Error: ${error.message}",
                loginMethod: loginMethod,
                passwordVisible: state.passwordVisible,
              ),
            );
            _log.error("session persist failed: {}", [error.message]);
        }
      case Failure(:final error):
        emit(
          LoginErrorState(
            message: errorMessage ?? "Login API Error: ${error.message}",
            loginMethod: loginMethod,
            passwordVisible: state.passwordVisible,
          ),
        );
        _log.error("getAccount failed: {}", [error.message]);
    }
  }
}
