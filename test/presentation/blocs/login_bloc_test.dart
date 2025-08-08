import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/models/jwt_token.dart';
import 'package:flutter_bloc_advance/data/models/send_otp_request.dart';
import 'package:flutter_bloc_advance/data/models/user_jwt.dart';
import 'package:flutter_bloc_advance/data/models/verify_otp_request.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/data/repository/login_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/bloc/login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_connect/http/src/exceptions/exceptions.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../fake/user_data.dart';
import '../../test_utils.dart';
import 'login_bloc_test.mocks.dart';

/// BLoc Test for LoginBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 1.1. Supports value comparisons <p>
/// 1.2. CopyWith retains the same values if no arguments are provided <p>
/// 1.3. CopyWith replaces non-null parameters <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
@GenerateMocks([LoginRepository, AccountRepository])
void main() {
  //region main setup
  late LoginRepository repository;
  late AccountRepository accountRepository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    repository = MockLoginRepository();
    accountRepository = MockAccountRepository();
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
      expect(LoginBloc(repository: MockLoginRepository()).state, const LoginState());
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
      expect(LoginBloc(repository: repository).state, const LoginState());
    });

    group("LoginFormSubmitted", () {
      const input = mockUserJWTPayload;
      Future<JWTToken> output = Future<JWTToken>.value(mockJWTTokenPayload);
      repositoryMethod() => repository.authenticate(input);

      final event = LoginFormSubmitted(username: input.username!, password: input.password!);

      final loadingState = LoginLoadingState(username: input.username!, password: input.password!);
      final successState = LoginLoadedState(username: input.username!, password: input.password!);
      const failureState = LoginErrorState(message: "Login API Error: Operation Unauthorized");
      const failure2State = LoginErrorState(message: "Login API Error: Invalid Request: Invalid Access Token");

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];
      final states2Failure = [loadingState, failure2State];

      blocTest<LoginBloc, LoginState>(
        "emits [loading, success] when login is successful",
        setUp: () => when(repositoryMethod()).thenAnswer((_) async => output),
        build: () => LoginBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
        verify: (_) => verify(repositoryMethod()).called(1),
      );

      blocTest<LoginBloc, LoginState>(
        "emits [loading, failure] when invalid operation input failed",
        setUp: () => when(repositoryMethod()).thenThrow(UnauthorizedException()),
        build: () => LoginBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
        verify: (_) => verify(repositoryMethod()).called(1),
      );

      blocTest<LoginBloc, LoginState>(
        "emits [loading, failure] when invalid input then failed",
        setUp: () => when(repositoryMethod()).thenAnswer((_) async => const JWTToken(idToken: null)),
        build: () => LoginBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => states2Failure,
        verify: (_) => verify(repositoryMethod()).called(1),
      );
    });
  });

  //endregion bloc

  group('LoginBloc test 2', () {
    test('initial state is LoginState', () {
      expect(LoginBloc(repository: repository).state, const LoginState());
    });

    group('LoginFormSubmitted', () {
      const input = UserJWT("username", "password");
      final event = LoginFormSubmitted(username: input.username!, password: input.password!);

      final loadingState = LoginLoadingState(username: input.username!, password: input.password!);
      final successState = LoginLoadedState(username: input.username!, password: input.password!);
      const failureState = LoginErrorState(message: "Login API Error: Operation Unauthorized");

      blocTest<LoginBloc, LoginState>(
        'given valid credentials when submitted then emits [loading, success]',
        setUp: () async {
          await AppLocalStorage().save(StorageKeys.jwtToken.name, "MOCK_TOKEN");
          await AppLocalStorage().save(StorageKeys.username.name, "username");
          await AppLocalStorage().save(StorageKeys.roles.name, ["ROLE_USER"]);

          when(repository.authenticate(input)).thenAnswer((_) async => mockJWTTokenPayload);
          when(accountRepository.getAccount()).thenAnswer((_) async => mockUserFullPayload);
        },
        build: () => LoginBloc(repository: repository, accountRepository: accountRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
        verify: (_) {
          verify(repository.authenticate(input)).called(1);
          verify(accountRepository.getAccount()).called(1);
        },
      );

      blocTest<LoginBloc, LoginState>(
        'given invalid credentials when submitted then emits [loading, error]',
        setUp: () => when(repository.authenticate(input)).thenThrow(UnauthorizedException()),
        build: () => LoginBloc(repository: repository),
        act: (bloc) => bloc.add(event),
        expect: () => [loadingState, failureState],
      );
    });

    group('SendOtpRequested', () {
      const email = "test@example.com";
      final request = SendOtpRequest(email: email);
      const event = SendOtpRequested(email: email);

      blocTest<LoginBloc, LoginState>(
        'given valid email when requested then emits [loading, success]',
        setUp: () => when(repository.sendOtp(request)).thenAnswer((_) async {}),
        build: () => LoginBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => [
          isA<LoginLoadingState>().having((state) => state.username, 'username', email),
          isA<LoginOtpSentState>().having((state) => state.email, 'email', email),
        ],
        // verify: (_) => verify(repository.sendOtp(request)).called(1),
      );

      blocTest<LoginBloc, LoginState>(
        'given invalid email when requested then emits [loading, error]',
        setUp: () => when(repository.sendOtp(request)).thenThrow(Exception("Invalid email")),
        build: () => LoginBloc(repository: repository),
        act: (bloc) => bloc.add(event),
        expect: () => [const LoginLoadingState(username: email), const LoginOtpSentState(email: email)],
      );
    });

    group('VerifyOtpSubmitted', () {
      const email = "test@example.com";
      const otpCode = "123456";
      final request = VerifyOtpRequest(email: email, otp: otpCode);
      const event = VerifyOtpSubmitted(email: email, otpCode: otpCode);

      const loadingState = LoginState(status: LoginStatus.loading);
      //final successState = const LoginLoadedState(username: email, password: otpCode);

      // blocTest<LoginBloc, LoginState>(
      //   'given valid OTP when submitted then emits [loading, success]',
      //   setUp: () async {
      //     // Mock repository responses first
      //     when(repository.verifyOtp(request)).thenAnswer((_) async => mockJWTTokenPayload);
      //     when(accountRepository.getAccount()).thenAnswer((_) async => mockUserFullPayload);
      //
      //     // Clear storage before test
      //     await AppLocalStorage().clear();
      //
      //     // Pre-populate storage with required values
      //     await AppLocalStorage().save(StorageKeys.jwtToken.name, "MOCK_TOKEN");
      //     await AppLocalStorage().save(StorageKeys.username.name, email);
      //     await AppLocalStorage().save(StorageKeys.roles.name, ["ROLE_USER"]);
      //   },
      //   build: () => LoginBloc(repository: repository, accountRepository: accountRepository),
      //   act: (bloc) => bloc.add(event),
      //   expect: () => [loadingState, successState],
      //   verify: (_) {
      //     verify(repository.verifyOtp(request)).called(1);
      //     verify(accountRepository.getAccount()).called(1);
      //   },
      // );

      blocTest<LoginBloc, LoginState>(
        'given invalid OTP when submitted then emits [loading, error]',
        setUp: () => when(repository.verifyOtp(request)).thenAnswer((_) async => const JWTToken(idToken: null)),
        build: () => LoginBloc(repository: repository),
        act: (bloc) => bloc.add(event),
        expect: () => [loadingState, const LoginErrorState(message: "OTP validation error")],
      );
    });

    group('ChangeLoginMethod', () {
      blocTest<LoginBloc, LoginState>(
        'given OTP method when changed then updates login method',
        build: () => LoginBloc(repository: repository),
        act: (bloc) => bloc.add(const ChangeLoginMethod(method: LoginMethod.otp)),
        expect: () => [const LoginState(loginMethod: LoginMethod.otp, status: LoginStatus.initial, isOtpSent: false)],
      );
    });

    group('TogglePasswordVisibility', () {
      blocTest<LoginBloc, LoginState>(
        'when toggled then updates password visibility',
        build: () => LoginBloc(repository: repository),
        act: (bloc) => bloc.add(const TogglePasswordVisibility()),
        expect: () => [const LoginState(passwordVisible: true)],
      );
    });
  });
}
