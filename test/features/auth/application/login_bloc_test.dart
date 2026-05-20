import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/persist_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/fake_data.dart';
import '../../../test_utils.dart';

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

  @override
  Future<Result<void>> changePassword(PasswordChangeDTO passwordChangeDTO) async => const Success(null);

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<UserEntity>> getAccount() async => Success(account ?? mockUserFullPayload);

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
  );
}

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
  );
}

void main() {
  //region main setup
  late _FakeAuthRepository repository;
  late _FakeAccountRepository accountRepository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    repository = _FakeAuthRepository();
    accountRepository = _FakeAccountRepository()..account = mockUserFullPayload;
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
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
      expect(const LoginLoadedState(username: "u").props, const <Object?>["u", LoginMethod.password, false]);
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
      final successState = LoginLoadedState(username: input.username);
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
      final successState = LoginLoadedState(username: input.username);
      const failureState = LoginErrorState(errorCode: AppErrorCode.authLoginFailed, message: "Unauthorized");

      blocTest<LoginBloc, LoginState>(
        'given valid credentials when submitted then emits [loading, success]',
        setUp: () async {
          await TestUtils().setupAuthentication();
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
}
