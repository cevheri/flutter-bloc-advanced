import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
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

LoginBloc _buildBloc(_FakeAuthRepository repository, [_FakeAccountRepository? accountRepository]) {
  final accountRepo = accountRepository ?? (_FakeAccountRepository()..account = mockUserFullPayload);
  return LoginBloc(
    authenticateUserUseCase: AuthenticateUserUseCase(repository),
    sendOtpUseCase: SendOtpUseCase(repository),
    verifyOtpUseCase: VerifyOtpUseCase(repository),
    getAccountUseCase: GetAccountUseCase(accountRepo),
  );
}

LoginBloc _buildBlocWithSendOtp(
  _FakeAuthRepositoryWithSendOtp repository, [
  _FakeAccountRepository? accountRepository,
]) {
  final accountRepo = accountRepository ?? (_FakeAccountRepository()..account = mockUserFullPayload);
  return LoginBloc(
    authenticateUserUseCase: AuthenticateUserUseCase(repository),
    sendOtpUseCase: SendOtpUseCase(repository),
    verifyOtpUseCase: VerifyOtpUseCase(repository),
    getAccountUseCase: GetAccountUseCase(accountRepo),
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
    // LoginState
    test("supports value comparisons", () {
      expect(const LoginState(), const LoginState());
      const state = LoginState(status: LoginStatus.initial, passwordVisible: false);
      expect(const LoginState(), state);
    });

    // LoginInitialState
    test("LoginInitialState", () {
      expect(const LoginInitialState(), const LoginInitialState());
    });

    // LoginLoadingState
    test("LoginLoadingState", () {
      expect(const LoginLoadingState(), const LoginLoadingState());
    });

    // LoginLoadedState
    test("LoginLoadedState", () {
      expect(const LoginLoadedState(), const LoginLoadedState());
    });

    // LoginErrorState
    test("LoginErrorState", () {
      expect(const LoginErrorState(message: "test"), const LoginErrorState(message: "test"));
      expect(const LoginErrorState(message: "test").props, ["test"]);
    });

    test("copyWith retains the same values if no arguments are provided", () {
      const state = LoginState(status: LoginStatus.initial, passwordVisible: false);
      expect(state.copyWith(), state);
    });

    test("copyWith replaces non-null parameters", () {
      const state = LoginState(status: LoginStatus.initial, passwordVisible: false);
      const secondState = LoginState(status: LoginStatus.success, passwordVisible: true);
      expect(state.copyWith(status: LoginStatus.success, passwordVisible: true), secondState);
    });

    test("Initial state is LoginState", () {
      expect(_buildBloc(_FakeAuthRepository()).state, const LoginState());
    });

    test("props", () {
      expect(
        const LoginState(status: LoginStatus.initial, passwordVisible: false, username: "test", password: "test").props,
        ["test", "test", LoginStatus.initial, false, null, null, false, LoginMethod.password],
      );
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
    test("initial state is LoginState", () {
      expect(_buildBloc(repository).state, const LoginState());
    });

    group("LoginFormSubmitted", () {
      const input = AuthCredentialsEntity(username: 'username', password: 'password');
      const output = AuthTokenEntity(idToken: 'MOCK_TOKEN');

      final event = LoginFormSubmitted(username: input.username, password: input.password);

      final loadingState = LoginLoadingState(username: input.username, password: input.password);
      final successState = LoginLoadedState(username: input.username, password: input.password);
      const failureState = LoginErrorState(message: "Login API Error: Unauthorized");
      const failure2State = LoginErrorState(message: "Login API Error: Invalid Access Token");

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
    test('initial state is LoginState', () {
      expect(_buildBloc(repository).state, const LoginState());
    });

    group('LoginFormSubmitted', () {
      const input = AuthCredentialsEntity(username: "username", password: "password");
      final event = LoginFormSubmitted(username: input.username, password: input.password);

      final loadingState = LoginLoadingState(username: input.username, password: input.password);
      final successState = LoginLoadedState(username: input.username, password: input.password);
      const failureState = LoginErrorState(message: "Login API Error: Unauthorized");

      blocTest<LoginBloc, LoginState>(
        'given valid credentials when submitted then emits [loading, success]',
        setUp: () async {
          await AppLocalStorage().save(StorageKeys.jwtToken.name, "MOCK_TOKEN");
          await AppLocalStorage().save(StorageKeys.username.name, "username");
          await AppLocalStorage().save(StorageKeys.roles.name, ["ROLE_USER"]);
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
        expect: () => [const LoginLoadingState(username: email), isA<LoginErrorState>()],
      );
    });

    group('VerifyOtpSubmitted', () {
      const email = "test@example.com";
      const otpCode = "123456";
      const event = VerifyOtpSubmitted(email: email, otpCode: otpCode);

      const loadingState = LoginState(status: LoginStatus.loading);

      blocTest<LoginBloc, LoginState>(
        'given invalid OTP when submitted then emits [loading, error]',
        setUp: () => repository.verifyResult = const Success(AuthTokenEntity(idToken: null)),
        build: () => _buildBloc(repository),
        act: (bloc) => bloc.add(event),
        expect: () => [loadingState, const LoginErrorState(message: "OTP validation error")],
      );
    });

    group('ChangeLoginMethod', () {
      blocTest<LoginBloc, LoginState>(
        'given OTP method when changed then updates login method',
        build: () => _buildBloc(repository),
        act: (bloc) => bloc.add(const ChangeLoginMethod(method: LoginMethod.otp)),
        expect: () => [const LoginState(loginMethod: LoginMethod.otp, status: LoginStatus.initial, isOtpSent: false)],
      );
    });

    group('TogglePasswordVisibility', () {
      blocTest<LoginBloc, LoginState>(
        'when toggled then updates password visibility',
        build: () => _buildBloc(repository),
        act: (bloc) => bloc.add(const TogglePasswordVisibility()),
        expect: () => [const LoginState(passwordVisible: true)],
      );
    });
  });
}
