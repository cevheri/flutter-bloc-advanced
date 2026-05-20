import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/persist_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

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
    required this._authenticateUserUseCase,
    required this._sendOtpUseCase,
    required this._verifyOtpUseCase,
    required this._getAccountUseCase,
    required this._persistAuthSessionUseCase,
  }) : super(const LoginInitialState()) {
    on<LoginFormSubmitted>(_onSubmit, transformer: EventTransformers.dropConcurrent());
    on<TogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<ChangeLoginMethod>(_onChangeLoginMethod);
    on<SendOtpRequested>(_onSendOtpRequested, transformer: EventTransformers.dropConcurrent());
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted, transformer: EventTransformers.dropConcurrent());
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
      LoginErrorState(:final errorCode, :final message) => LoginErrorState(
        errorCode: errorCode,
        message: message,
        loginMethod: m,
        passwordVisible: v,
      ),
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

    final credentials = AuthCredentialsEntity(username: event.username, password: event.password);
    final tokenResult = await _authenticateUserUseCase(credentials);
    switch (tokenResult) {
      case Success(:final data):
        if (!data.isValid) {
          emit(
            LoginErrorState(
              errorCode: AppErrorCode.authInvalidAccessToken,
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
            errorCode: AppErrorCode.authLoginFailed,
            message: error.message,
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
            errorCode: AppErrorCode.authSendOtpFailed,
            message: error.message,
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
              errorCode: AppErrorCode.authOtpValidationError,
              loginMethod: LoginMethod.otp,
              passwordVisible: state.passwordVisible,
            ),
          );
          return;
        }
        await _completeLogin(token: data, username: event.email, loginMethod: LoginMethod.otp, emit: emit);
      case Failure(:final error):
        emit(
          LoginErrorState(
            errorCode: AppErrorCode.authOtpValidationError,
            message: error.message,
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
  ///
  /// Two-phase persistence is intentional: the token + username MUST be
  /// in storage before `_getAccountUseCase()` runs, because the HTTP
  /// `AuthInterceptor` reads the JWT from storage to attach the
  /// Authorization header. After the account is resolved we re-persist
  /// with the user's authorities included.
  Future<void> _completeLogin({
    required AuthTokenEntity token,
    required String username,
    required LoginMethod loginMethod,
    required Emitter<LoginState> emit,
  }) async {
    // Phase 1: persist token-bearing fields so AuthInterceptor can read
    // the JWT for the upcoming account request.
    final preSession = AuthSession(idToken: token.idToken!, refreshToken: token.refreshToken, username: username);
    final preResult = await _persistAuthSessionUseCase(preSession);
    if (preResult is Failure<void>) {
      emit(
        LoginErrorState(
          errorCode: AppErrorCode.authSessionPersistFailed,
          message: preResult.error.message,
          loginMethod: loginMethod,
          passwordVisible: state.passwordVisible,
        ),
      );
      _log.error("session pre-persist failed: {}", [preResult.error.message]);
      return;
    }

    final accountResult = await _getAccountUseCase();
    switch (accountResult) {
      case Success(data: final user):
        // Phase 2: re-persist with authorities included.
        final fullSession = AuthSession(
          idToken: token.idToken!,
          refreshToken: token.refreshToken,
          username: username,
          roles: user.authorities ?? const [],
        );
        final fullResult = await _persistAuthSessionUseCase(fullSession);
        switch (fullResult) {
          case Success():
            emit(
              LoginLoadedState(username: username, loginMethod: loginMethod, passwordVisible: state.passwordVisible),
            );
            _log.debug("session persisted for: {}", [username]);
          case Failure(:final error):
            emit(
              LoginErrorState(
                errorCode: AppErrorCode.authSessionPersistFailed,
                message: error.message,
                loginMethod: loginMethod,
                passwordVisible: state.passwordVisible,
              ),
            );
            _log.error("session roles-persist failed: {}", [error.message]);
        }
      case Failure(:final error):
        emit(
          LoginErrorState(
            errorCode: AppErrorCode.authLoginFailed,
            message: error.message,
            loginMethod: loginMethod,
            passwordVisible: state.passwordVisible,
          ),
        );
        _log.error("getAccount failed: {}", [error.message]);
    }
  }
}
