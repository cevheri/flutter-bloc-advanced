import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/clear_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/persist_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/sign_in_with_sso_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_auth_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;

import '../../../mocks/fake_data.dart';
import '../../../support/test_env.dart';

class _FakeAuthRepository implements IAuthRepository {
  Result<AuthTokenEntity>? authenticateResult;
  Result<AuthTokenEntity>? verifyResult;

  @override
  Future<Result<AuthTokenEntity>> authenticate(AuthCredentialsEntity userJWT) async {
    return authenticateResult ?? const Failure(UnknownError("No result configured"));
  }

  @override
  Future<Result<void>> logout() async {
    return const Success(null);
  }

  @override
  Future<Result<void>> sendOtp(SendOtpEntity request) async {
    return const Success(null);
  }

  @override
  Future<Result<AuthTokenEntity>> verifyOtp(VerifyOtpEntity request) async {
    return verifyResult ?? const Failure(UnknownError("No result configured"));
  }
}

class _FakeAuthRepositoryWithSendOtp implements IAuthRepository {
  Result<void>? sendOtpResult;
  Result<AuthTokenEntity>? authenticateResult;
  Result<AuthTokenEntity>? verifyResult;

  @override
  Future<Result<AuthTokenEntity>> authenticate(AuthCredentialsEntity userJWT) async {
    return authenticateResult ?? const Failure(UnknownError("No result configured"));
  }

  @override
  Future<Result<void>> logout() async {
    return const Success(null);
  }

  @override
  Future<Result<void>> sendOtp(SendOtpEntity request) async {
    return sendOtpResult ?? const Success(null);
  }

  @override
  Future<Result<AuthTokenEntity>> verifyOtp(VerifyOtpEntity request) async {
    return verifyResult ?? const Failure(UnknownError("No result configured"));
  }
}

class _FakeAuthSessionRepository implements IAuthSessionRepository {
  Result<void>? persistResult;
  final persisted = <AuthSession>[];

  @override
  Future<Result<void>> persist(AuthSession session) async {
    persisted.add(session);
    return persistResult ?? const Success(null);
  }

  @override
  Future<Result<void>> clear() async => const Success(null);
}

class _FakeAccountRepository implements IAccountRepository {
  UserEntity? account;
  Result<UserEntity>? getAccountResult;
  int getAccountCalls = 0;

  @override
  Future<Result<void>> changePassword(PasswordChangeDTO passwordChangeDTO) async => const Success(null);

  @override
  Future<Result<UserEntity>> getAccount() async {
    getAccountCalls++;
    return getAccountResult ?? Success(account ?? mockUserFullPayload);
  }

  @override
  Future<Result<UserEntity>> register(UserEntity newUser) async => Success(newUser);

  @override
  Future<Result<void>> resetPassword(String mailAddress) async => const Success(null);

  @override
  Future<Result<UserEntity>> update(UserEntity user) async => Success(user);
}

LoginBloc _buildBloc(
  _FakeAuthRepository repository, [
  _FakeAccountRepository? accountRepository,
  _FakeAuthSessionRepository? sessionRepository,
]) {
  final accountRepo = accountRepository ?? (_FakeAccountRepository()..account = mockUserFullPayload);
  final sessionRepo = sessionRepository ?? _FakeAuthSessionRepository();
  return LoginBloc(
    authenticateUserUseCase: AuthenticateUserUseCase(repository),
    sendOtpUseCase: SendOtpUseCase(repository),
    verifyOtpUseCase: VerifyOtpUseCase(repository),
    getAccountUseCase: GetAccountUseCase(accountRepo),
    persistAuthSessionUseCase: PersistAuthSessionUseCase(sessionRepo),
    clearAuthSessionUseCase: ClearAuthSessionUseCase(sessionRepo),
  );
}

/// Answers each sign-in with [result], or with [pending] once it completes when it is set, and counts the sign-ins.
class _FakeSsoAuthRepository implements ISsoAuthRepository {
  SsoSignInResult result = const SsoSignInCancelled();
  Completer<SsoSignInResult>? pending;
  int signIns = 0;

  @override
  Future<SsoSignInResult> signIn({String? webReturnPath, required String browserDoneMessage}) async {
    signIns++;
    return pending?.future ?? result;
  }

  @override
  Future<SsoSignInResult?> completePendingSignIn() => throw UnimplementedError('LoginBloc never completes a sign-in');
}

LoginBloc _buildSsoBloc(_FakeSsoAuthRepository ssoRepository, _FakeAccountRepository accountRepository) => LoginBloc(
  authenticateUserUseCase: AuthenticateUserUseCase(_FakeAuthRepository()),
  sendOtpUseCase: SendOtpUseCase(_FakeAuthRepository()),
  verifyOtpUseCase: VerifyOtpUseCase(_FakeAuthRepository()),
  getAccountUseCase: GetAccountUseCase(accountRepository),
  persistAuthSessionUseCase: PersistAuthSessionUseCase(_FakeAuthSessionRepository()),
  clearAuthSessionUseCase: ClearAuthSessionUseCase(_FakeAuthSessionRepository()),
  signInWithSsoUseCase: SignInWithSsoUseCase(ssoRepository),
);

LoginBloc _buildBlocWithSendOtp(
  _FakeAuthRepositoryWithSendOtp repository, [
  _FakeAccountRepository? accountRepository,
  _FakeAuthSessionRepository? sessionRepository,
]) {
  final accountRepo = accountRepository ?? (_FakeAccountRepository()..account = mockUserFullPayload);
  final sessionRepo = sessionRepository ?? _FakeAuthSessionRepository();
  return LoginBloc(
    authenticateUserUseCase: AuthenticateUserUseCase(repository),
    sendOtpUseCase: SendOtpUseCase(repository),
    verifyOtpUseCase: VerifyOtpUseCase(repository),
    getAccountUseCase: GetAccountUseCase(accountRepo),
    persistAuthSessionUseCase: PersistAuthSessionUseCase(sessionRepo),
    clearAuthSessionUseCase: ClearAuthSessionUseCase(sessionRepo),
  );
}

/// The secure store the session lives in, held in memory, so a test can see what a sign-in leaves behind.
class _MemorySecureStorage implements ISecureStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}

/// Stores through [inner], but refuses the second write of a sign-in, the one that carries the roles, and can refuse
/// the clear.
class _StoreSessionRepository implements IAuthSessionRepository {
  _StoreSessionRepository(this.inner);

  final IAuthSessionRepository inner;
  bool failRolesPersist = false;
  Result<void>? clearResult;
  int clears = 0;

  @override
  Future<Result<void>> persist(AuthSession session) async {
    if (failRolesPersist && session.roles.isNotEmpty) return const Failure(UnknownError('roles write refused'));
    return inner.persist(session);
  }

  @override
  Future<Result<void>> clear() async {
    clears++;
    return clearResult ?? inner.clear();
  }
}

LoginBloc _buildStoreBloc(
  _FakeAuthRepository repository,
  _FakeAccountRepository accountRepository,
  IAuthSessionRepository sessionRepository,
) => LoginBloc(
  authenticateUserUseCase: AuthenticateUserUseCase(repository),
  sendOtpUseCase: SendOtpUseCase(repository),
  verifyOtpUseCase: VerifyOtpUseCase(repository),
  getAccountUseCase: GetAccountUseCase(accountRepository),
  persistAuthSessionUseCase: PersistAuthSessionUseCase(sessionRepository),
  clearAuthSessionUseCase: ClearAuthSessionUseCase(sessionRepository),
);

void main() {
  //region main setup
  late _FakeAuthRepository repository;
  late _FakeAccountRepository accountRepository;

  setUp(() {
    repository = _FakeAuthRepository();
    accountRepository = _FakeAccountRepository()..account = mockUserFullPayload;
  });

  //endregion main setup

  //region state
  /// Login State Tests
  group("LoginState", () {
    test("LoginInitialState equality and props", () {
      expect(const LoginInitialState(), const LoginInitialState());
      expect(const LoginInitialState().props, const <Object?>[LoginMethod.password, false]);
    });

    test("LoginLoadingState carries username", () {
      expect(const LoginLoadingState(username: "u"), const LoginLoadingState(username: "u"));
      expect(const LoginLoadingState(username: "u").props, const <Object?>["u", LoginMethod.password, false]);
    });

    test("LoginLoadedState carries username", () {
      expect(const LoginLoadedState(username: "u"), const LoginLoadedState(username: "u"));
      expect(const LoginLoadedState(username: "u").props, const <Object?>[
        "u",
        <String>[],
        LoginMethod.password,
        false,
      ]);
    });

    test("LoginLoadedState carries roles", () {
      const state = LoginLoadedState(username: "u", roles: ["ROLE_ADMIN"]);
      expect(state.roles, const ["ROLE_ADMIN"]);
      expect(state, const LoginLoadedState(username: "u", roles: ["ROLE_ADMIN"]));
      expect(state, isNot(const LoginLoadedState(username: "u")));
    });

    test("LoginOtpSentState carries email", () {
      expect(const LoginOtpSentState(email: "e@x"), const LoginOtpSentState(email: "e@x"));
      expect(const LoginOtpSentState(email: "e@x").loginMethod, LoginMethod.otp);
    });

    test("LoginOtpVerifiedState carries email + otpCode", () {
      expect(
        const LoginOtpVerifiedState(email: "e@x", otpCode: "123"),
        const LoginOtpVerifiedState(email: "e@x", otpCode: "123"),
      );
    });

    test("LoginErrorState carries code + optional message", () {
      expect(
        const LoginErrorState(errorCode: AppErrorCode.authLoginFailed, message: "test"),
        const LoginErrorState(errorCode: AppErrorCode.authLoginFailed, message: "test"),
      );
      expect(const LoginErrorState(errorCode: AppErrorCode.authLoginFailed, message: "test").props, const <Object?>[
        AppErrorCode.authLoginFailed,
        "test",
        LoginMethod.password,
        false,
      ]);
    });

    test("Initial bloc state is LoginInitialState", () {
      expect(_buildBloc(_FakeAuthRepository()).state, const LoginInitialState());
    });

    test("passwordVisible flows through variants", () {
      expect(const LoginInitialState(passwordVisible: true).passwordVisible, true);
      expect(const LoginLoadingState(passwordVisible: true).passwordVisible, true);
    });
  });
  //endregion state

  //region event
  /// Login Event Tests
  group("LoginEvent", () {
    test("supports value comparisons", () {
      expect(
        const LoginFormSubmitted(username: "test", password: "test"),
        const LoginFormSubmitted(username: "test", password: "test"),
      );
    });
    test("TogglePasswordVisibility", () {
      expect(const TogglePasswordVisibility(), const TogglePasswordVisibility());
    });
    test("props", () {
      expect(const LoginFormSubmitted(username: "test", password: "test").props, ["test", "test"]);
      expect(const TogglePasswordVisibility().props, []);
    });
  });

  // Regression: with stringify on, the default of every debug build, these printed the password and the code, and the
  // debug observer records the text of every event and state in the dev console.
  group("text of the credential events and states", () {
    test("LoginFormSubmitted names the user and leaves the password out", () {
      final text = const LoginFormSubmitted(username: "admin", password: "S3cret!pw").toString();

      expect(text, allOf(startsWith("LoginFormSubmitted("), contains("admin"), isNot(contains("S3cret!pw"))));
    });

    test("VerifyOtpSubmitted names the email and leaves the code out", () {
      final text = const VerifyOtpSubmitted(email: "otp.user@example.com", otpCode: "493817").toString();

      expect(
        text,
        allOf(startsWith("VerifyOtpSubmitted("), contains("otp.user@example.com"), isNot(contains("493817"))),
      );
    });

    test("LoginOtpVerifiedState names the email and leaves the code out", () {
      final text = const LoginOtpVerifiedState(email: "otp.user@example.com", otpCode: "493817").toString();

      expect(
        text,
        allOf(startsWith("LoginOtpVerifiedState("), contains("otp.user@example.com"), isNot(contains("493817"))),
      );
    });
  });
  //endregion event

  //region bloc
  /// Login Bloc Tests
  group("LoginBloc", () {
    test("initial state is LoginInitialState", () {
      expect(_buildBloc(repository).state, const LoginInitialState());
    });

    group("LoginFormSubmitted", () {
      const input = AuthCredentialsEntity(username: 'username', password: 'password');
      const output = AuthTokenEntity(idToken: 'MOCK_TOKEN');

      final event = LoginFormSubmitted(username: input.username, password: input.password);

      final loadingState = LoginLoadingState(username: input.username);
      // Roles come from the resolved account (mockUserFullPayload → ROLE_USER)
      // and are now carried on the success state.
      final successState = LoginLoadedState(username: input.username, roles: const ['ROLE_USER']);
      const failureState = LoginErrorState(errorCode: AppErrorCode.authLoginFailed, message: "Unauthorized");
      const failure2State = LoginErrorState(errorCode: AppErrorCode.authInvalidAccessToken);

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];
      final states2Failure = [loadingState, failure2State];

      blocTest<LoginBloc, LoginState>(
        "emits [loading, success] when login is successful",
        setUp: () {
          repository.authenticateResult = const Success(output);
        },
        build: () => _buildBloc(repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );

      blocTest<LoginBloc, LoginState>(
        "emits [loading, failure] when invalid operation input failed",
        setUp: () {
          repository.authenticateResult = const Failure(AuthError("Unauthorized"));
        },
        build: () => _buildBloc(repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );

      blocTest<LoginBloc, LoginState>(
        "emits [loading, failure] when invalid input then failed",
        setUp: () {
          repository.authenticateResult = const Success(AuthTokenEntity(idToken: null));
        },
        build: () => _buildBloc(repository),
        act: (bloc) => bloc..add(event),
        expect: () => states2Failure,
      );
    });

    // LoginBloc outlives the session; AppSessionListeners resets it when the session ends.
    blocTest<LoginBloc, LoginState>(
      "LoginReset forgets the signed-in user and hides the password again",
      build: () => _buildBloc(repository),
      seed: () => const LoginLoadedState(username: "admin", roles: ["ROLE_ADMIN"], passwordVisible: true),
      act: (bloc) => bloc.add(const LoginReset()),
      expect: () => [const LoginInitialState()],
    );
  });

  //endregion bloc

  group('LoginBloc test 2', () {
    test('initial state is LoginInitialState', () {
      expect(_buildBloc(repository).state, const LoginInitialState());
    });

    group('LoginFormSubmitted', () {
      const input = AuthCredentialsEntity(username: "username", password: "password");
      final event = LoginFormSubmitted(username: input.username, password: input.password);

      final loadingState = LoginLoadingState(username: input.username);
      final successState = LoginLoadedState(username: input.username, roles: const ['ROLE_USER']);
      const failureState = LoginErrorState(errorCode: AppErrorCode.authLoginFailed, message: "Unauthorized");

      blocTest<LoginBloc, LoginState>(
        'given valid credentials when submitted then emits [loading, success]',
        setUp: () async {
          TestEnv.authenticate();
          await AppLocalStorage().save(StorageKeys.username.key, "username");
          await AppLocalStorage().save(StorageKeys.roles.key, ["ROLE_USER"]);
          repository.authenticateResult = const Success(AuthTokenEntity(idToken: 'MOCK_TOKEN'));
        },
        build: () => _buildBloc(repository, accountRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
      );

      blocTest<LoginBloc, LoginState>(
        'given invalid credentials when submitted then emits [loading, error]',
        setUp: () => repository.authenticateResult = const Failure(AuthError("Unauthorized")),
        build: () => _buildBloc(repository),
        act: (bloc) => bloc.add(event),
        expect: () => [loadingState, failureState],
      );
    });

    group('SendOtpRequested', () {
      const email = "test@example.com";
      const event = SendOtpRequested(email: email);

      blocTest<LoginBloc, LoginState>(
        'given valid email when requested then emits [loading, success]',
        build: () => _buildBloc(repository),
        act: (bloc) => bloc..add(event),
        expect: () => [
          isA<LoginLoadingState>().having((state) => state.username, 'username', email),
          isA<LoginOtpSentState>().having((state) => state.email, 'email', email),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'given invalid email when requested then emits [loading, error]',
        build: () {
          final sendOtpRepo = _FakeAuthRepositoryWithSendOtp()
            ..sendOtpResult = const Failure(ValidationError("Invalid email"));
          return _buildBlocWithSendOtp(sendOtpRepo);
        },
        act: (bloc) => bloc.add(event),
        expect: () => [const LoginLoadingState(username: email, loginMethod: LoginMethod.otp), isA<LoginErrorState>()],
      );
    });

    group('VerifyOtpSubmitted', () {
      const email = "test@example.com";
      const otpCode = "123456";
      const event = VerifyOtpSubmitted(email: email, otpCode: otpCode);

      const loadingState = LoginLoadingState(username: email, loginMethod: LoginMethod.otp);

      blocTest<LoginBloc, LoginState>(
        'given invalid OTP when submitted then emits [loading, error]',
        setUp: () => repository.verifyResult = const Success(AuthTokenEntity(idToken: null)),
        build: () => _buildBloc(repository),
        act: (bloc) => bloc.add(event),
        expect: () => [
          loadingState,
          const LoginErrorState(errorCode: AppErrorCode.authOtpValidationError, loginMethod: LoginMethod.otp),
        ],
      );
    });

    group('ChangeLoginMethod', () {
      blocTest<LoginBloc, LoginState>(
        'given OTP method when changed then updates login method',
        build: () => _buildBloc(repository),
        act: (bloc) => bloc.add(const ChangeLoginMethod(method: LoginMethod.otp)),
        expect: () => [const LoginInitialState(loginMethod: LoginMethod.otp)],
      );
    });

    group('TogglePasswordVisibility', () {
      blocTest<LoginBloc, LoginState>(
        'when toggled then updates password visibility',
        build: () => _buildBloc(repository),
        act: (bloc) => bloc.add(const TogglePasswordVisibility()),
        expect: () => [const LoginInitialState(passwordVisible: true)],
      );
    });

    // Regression coverage for #71: the bloc must delegate session
    // persistence to PersistAuthSessionUseCase and never reach into
    // storage directly. We verify both the call shape on success and
    // that a persistence failure surfaces as a LoginErrorState.
    group('PersistAuthSession (#71)', () {
      const event = LoginFormSubmitted(username: "username", password: "password");
      late _FakeAuthSessionRepository sessionRepo;

      setUp(() {
        sessionRepo = _FakeAuthSessionRepository();
      });

      blocTest<LoginBloc, LoginState>(
        'invokes PersistAuthSessionUseCase TWICE (pre-account then with roles) on success',
        setUp: () {
          repository.authenticateResult = const Success(
            AuthTokenEntity(idToken: "MOCK_TOKEN", refreshToken: "MOCK_REFRESH"),
          );
        },
        build: () => _buildBloc(repository, accountRepository, sessionRepo),
        act: (bloc) => bloc.add(event),
        verify: (_) {
          // Two-phase persistence: pre-session lacks roles (interceptor
          // needs JWT before getAccount); full-session includes roles.
          expect(sessionRepo.persisted, hasLength(2));
          expect(sessionRepo.persisted.first.idToken, "MOCK_TOKEN");
          expect(sessionRepo.persisted.first.refreshToken, "MOCK_REFRESH");
          expect(sessionRepo.persisted.first.username, "username");
          expect(sessionRepo.persisted.first.roles, isEmpty);
          expect(sessionRepo.persisted.last.idToken, "MOCK_TOKEN");
          expect(sessionRepo.persisted.last.roles, isNotEmpty);
        },
      );

      blocTest<LoginBloc, LoginState>(
        'emits LoginErrorState when session persistence fails',
        setUp: () {
          repository.authenticateResult = const Success(AuthTokenEntity(idToken: "MOCK_TOKEN"));
          sessionRepo.persistResult = const Failure(UnknownError("disk full"));
        },
        build: () => _buildBloc(repository, accountRepository, sessionRepo),
        act: (bloc) => bloc.add(event),
        expect: () => [
          const LoginLoadingState(username: "username"),
          isA<LoginErrorState>().having((s) => s.message, 'message', contains('disk full')),
        ],
      );
    });
  });

  // Regression: every failed sign-in step reported its own generic code, so a certificate that matched no pin read
  // "Login failed", as if the credentials were wrong. A code the failure carries now reaches the screen.
  group('a failure that carries an AppErrorCode', () {
    const certInvalid = NetworkError('pin mismatch', code: 'network.cert_invalid');

    blocTest<LoginBloc, LoginState>(
      'LoginFormSubmitted emits the code of a failed sign-in',
      setUp: () => repository.authenticateResult = const Failure(certInvalid),
      build: () => _buildBloc(repository),
      act: (bloc) => bloc.add(const LoginFormSubmitted(username: 'username', password: 'password')),
      expect: () => [
        const LoginLoadingState(username: 'username'),
        const LoginErrorState(errorCode: AppErrorCode.networkCertInvalid, message: 'pin mismatch'),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'LoginFormSubmitted emits the code of a failed account fetch after the sign-in',
      setUp: () {
        repository.authenticateResult = const Success(AuthTokenEntity(idToken: 'MOCK_TOKEN'));
        accountRepository.getAccountResult = const Failure(certInvalid);
      },
      build: () => _buildBloc(repository, accountRepository),
      act: (bloc) => bloc.add(const LoginFormSubmitted(username: 'username', password: 'password')),
      expect: () => [
        const LoginLoadingState(username: 'username'),
        const LoginErrorState(errorCode: AppErrorCode.networkCertInvalid, message: 'pin mismatch'),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'SendOtpRequested emits the code of a failed send',
      build: () => _buildBlocWithSendOtp(_FakeAuthRepositoryWithSendOtp()..sendOtpResult = const Failure(certInvalid)),
      act: (bloc) => bloc.add(const SendOtpRequested(email: 'test@example.com')),
      expect: () => [
        const LoginLoadingState(username: 'test@example.com', loginMethod: LoginMethod.otp),
        const LoginErrorState(
          errorCode: AppErrorCode.networkCertInvalid,
          message: 'pin mismatch',
          loginMethod: LoginMethod.otp,
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'VerifyOtpSubmitted emits the code of a failed verification',
      setUp: () => repository.verifyResult = const Failure(certInvalid),
      build: () => _buildBloc(repository),
      act: (bloc) => bloc.add(const VerifyOtpSubmitted(email: 'test@example.com', otpCode: '123456')),
      expect: () => [
        const LoginLoadingState(username: 'test@example.com', loginMethod: LoginMethod.otp),
        const LoginErrorState(
          errorCode: AppErrorCode.networkCertInvalid,
          message: 'pin mismatch',
          loginMethod: LoginMethod.otp,
        ),
      ],
    );
  });

  // Regression: the token is stored before GET /account so the request can carry it, and a sign-in whose account
  // fetch, or whose second write, failed showed "sign-in failed" but left that token stored, so the next launch opened
  // signed in as that user.
  group('a sign-in that fails after the token is stored', () {
    const token = AuthTokenEntity(idToken: 'MOCK_TOKEN', refreshToken: 'MOCK_REFRESH');
    const accountDown = NetworkError('account down', code: 'network.cert_invalid');
    late _MemorySecureStorage secureStorage;
    late _StoreSessionRepository sessionRepository;

    setUp(() {
      secureStorage = _MemorySecureStorage();
      sessionRepository = _StoreSessionRepository(AuthSessionRepository(secureStorage: secureStorage));
    });

    Future<void> expectNoStoredSession() async {
      expect(secureStorage.values, isEmpty);
      expect(await AppLocalStorage().read(StorageKeys.username.key), isNull);
      expect(await AppLocalStorage().read(StorageKeys.roles.key), isNull);
    }

    blocTest<LoginBloc, LoginState>(
      'a password sign-in whose account fetch fails leaves no session stored',
      setUp: () {
        repository.authenticateResult = const Success(token);
        accountRepository.getAccountResult = const Failure(accountDown);
      },
      build: () => _buildStoreBloc(repository, accountRepository, sessionRepository),
      act: (bloc) => bloc.add(const LoginFormSubmitted(username: 'username', password: 'password')),
      expect: () => [
        const LoginLoadingState(username: 'username'),
        const LoginErrorState(errorCode: AppErrorCode.networkCertInvalid, message: 'account down'),
      ],
      verify: (_) => expectNoStoredSession(),
    );

    blocTest<LoginBloc, LoginState>(
      'a password sign-in whose roles write fails leaves no session stored',
      setUp: () {
        repository.authenticateResult = const Success(token);
        sessionRepository.failRolesPersist = true;
      },
      build: () => _buildStoreBloc(repository, accountRepository, sessionRepository),
      act: (bloc) => bloc.add(const LoginFormSubmitted(username: 'username', password: 'password')),
      expect: () => [
        const LoginLoadingState(username: 'username'),
        const LoginErrorState(errorCode: AppErrorCode.authSessionPersistFailed, message: 'roles write refused'),
      ],
      verify: (_) => expectNoStoredSession(),
    );

    blocTest<LoginBloc, LoginState>(
      'an OTP sign-in whose account fetch fails leaves no session stored',
      setUp: () {
        repository.verifyResult = const Success(token);
        accountRepository.getAccountResult = const Failure(accountDown);
      },
      build: () => _buildStoreBloc(repository, accountRepository, sessionRepository),
      act: (bloc) => bloc.add(const VerifyOtpSubmitted(email: 'test@example.com', otpCode: '123456')),
      expect: () => [
        const LoginLoadingState(username: 'test@example.com', loginMethod: LoginMethod.otp),
        const LoginErrorState(
          errorCode: AppErrorCode.networkCertInvalid,
          message: 'account down',
          loginMethod: LoginMethod.otp,
        ),
      ],
      verify: (_) => expectNoStoredSession(),
    );

    blocTest<LoginBloc, LoginState>(
      'a sign-in that succeeds keeps the session stored',
      setUp: () => repository.authenticateResult = const Success(token),
      build: () => _buildStoreBloc(repository, accountRepository, sessionRepository),
      act: (bloc) => bloc.add(const LoginFormSubmitted(username: 'username', password: 'password')),
      expect: () => [
        const LoginLoadingState(username: 'username'),
        const LoginLoadedState(username: 'username', roles: ['ROLE_USER']),
      ],
      verify: (_) async {
        expect(sessionRepository.clears, 0);
        expect(secureStorage.values, {
          SecureStorageKeys.jwtToken.key: 'MOCK_TOKEN',
          SecureStorageKeys.refreshToken.key: 'MOCK_REFRESH',
        });
        expect(await AppLocalStorage().read(StorageKeys.username.key), 'username');
        expect(await AppLocalStorage().read(StorageKeys.roles.key), ['ROLE_USER']);
      },
    );

    group('when the clear fails too', () {
      late List<String> errorLines;

      setUp(() {
        errorLines = [];
        void collect(OutputEvent event) {
          if (event.level == Level.error) errorLines.addAll(event.lines);
        }

        Logger.addOutputListener(collect);
        addTearDown(() => Logger.removeOutputListener(collect));
      });

      blocTest<LoginBloc, LoginState>(
        'still emits the sign-in error and logs the clear failure at error level without the token',
        setUp: () {
          repository.authenticateResult = const Success(token);
          accountRepository.getAccountResult = const Failure(accountDown);
          sessionRepository.clearResult = const Failure(UnknownError('Session clear failed: jwt: keystore locked'));
        },
        build: () => _buildStoreBloc(repository, accountRepository, sessionRepository),
        act: (bloc) => bloc.add(const LoginFormSubmitted(username: 'username', password: 'password')),
        expect: () => [
          const LoginLoadingState(username: 'username'),
          const LoginErrorState(errorCode: AppErrorCode.networkCertInvalid, message: 'account down'),
        ],
        verify: (_) {
          expect(sessionRepository.clears, 1);
          expect(errorLines.join('\n'), contains('Session clear failed: jwt: keystore locked'));
          expect(errorLines.join('\n'), isNot(contains('MOCK_TOKEN')));
          expect(errorLines.join('\n'), isNot(contains('MOCK_REFRESH')));
        },
      );
    });
  });

  group('single sign-on', () {
    late _FakeSsoAuthRepository ssoRepository;

    setUp(() => ssoRepository = _FakeSsoAuthRepository());

    blocTest<LoginBloc, LoginState>(
      'emits the signed-in state with the username and roles the sign-in gives, without reading the account',
      setUp: () => ssoRepository.result = const SsoSignInSucceeded(
        username: 'admin@example.com',
        roles: ['ROLE_ADMIN', 'ROLE_USER'],
      ),
      build: () => _buildSsoBloc(ssoRepository, accountRepository),
      act: (bloc) => bloc.add(const SsoSignInRequested(browserDoneMessage: 'done')),
      expect: () => [
        const LoginLoadingState(),
        const LoginLoadedState(username: 'admin@example.com', roles: ['ROLE_ADMIN', 'ROLE_USER']),
      ],
      verify: (_) => expect(accountRepository.getAccountCalls, 0),
    );

    blocTest<LoginBloc, LoginState>(
      'returns to the blank sign-in when the user cancels',
      setUp: () => ssoRepository.result = const SsoSignInCancelled(),
      build: () => _buildSsoBloc(ssoRepository, accountRepository),
      act: (bloc) => bloc.add(const SsoSignInRequested(browserDoneMessage: 'done')),
      expect: () => [const LoginLoadingState(), const LoginInitialState()],
    );

    blocTest<LoginBloc, LoginState>(
      'emits the error code of a rejected sign-in',
      setUp: () => ssoRepository.result = const SsoSignInRejected(AppErrorCode.authOidcNoRole),
      build: () => _buildSsoBloc(ssoRepository, accountRepository),
      act: (bloc) => bloc.add(const SsoSignInRequested(browserDoneMessage: 'done')),
      expect: () => [const LoginLoadingState(), const LoginErrorState(errorCode: AppErrorCode.authOidcNoRole)],
      verify: (_) => expect(accountRepository.getAccountCalls, 0),
    );

    blocTest<LoginBloc, LoginState>(
      'stays loading while the web tab is on its way to the provider',
      setUp: () => ssoRepository.result = const SsoSignInNavigatedAway(),
      build: () => _buildSsoBloc(ssoRepository, accountRepository),
      act: (bloc) => bloc.add(const SsoSignInRequested(webReturnPath: '/users', browserDoneMessage: 'done')),
      expect: () => [const LoginLoadingState()],
    );

    blocTest<LoginBloc, LoginState>(
      'drops a second request while the first sign-in is running',
      setUp: () => ssoRepository.pending = Completer<SsoSignInResult>(),
      build: () => _buildSsoBloc(ssoRepository, accountRepository),
      act: (bloc) async {
        bloc.add(const SsoSignInRequested(browserDoneMessage: 'done'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SsoSignInRequested(browserDoneMessage: 'done'));
        await Future<void>.delayed(Duration.zero);
        ssoRepository.pending!.complete(const SsoSignInSucceeded(username: 'jdoe', roles: ['ROLE_USER']));
      },
      expect: () => [
        const LoginLoadingState(),
        const LoginLoadedState(username: 'jdoe', roles: ['ROLE_USER']),
      ],
      verify: (_) => expect(ssoRepository.signIns, 1),
    );

    blocTest<LoginBloc, LoginState>(
      'throws when the build has no single sign-on',
      build: () => _buildBloc(repository),
      act: (bloc) => bloc.add(const SsoSignInRequested(browserDoneMessage: 'done')),
      expect: () => <LoginState>[],
      errors: () => [
        isA<StateError>().having((e) => e.message, 'message', 'single sign-on is not enabled in this build'),
      ],
    );

    test('SsoSignInRequested compares by its return path and browser message', () {
      expect(
        const SsoSignInRequested(webReturnPath: '/users', browserDoneMessage: 'done'),
        const SsoSignInRequested(webReturnPath: '/users', browserDoneMessage: 'done'),
      );
      expect(
        const SsoSignInRequested(webReturnPath: '/users', browserDoneMessage: 'done'),
        isNot(const SsoSignInRequested(browserDoneMessage: 'done')),
      );
    });
  });
}
