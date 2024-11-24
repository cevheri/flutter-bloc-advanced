import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/jwt_token.dart';
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
@GenerateMocks([LoginRepository])
void main() {
  //region main setup
  late LoginRepository repository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    repository = MockLoginRepository();
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
      expect(LoginBloc(loginRepository: MockLoginRepository()).state, const LoginState());
    });

    test("props", () {
      expect(const LoginState(status: LoginStatus.initial, passwordVisible: false, username: "test", password: "test").props,
          ["test", "test", LoginStatus.initial, false]);
    });
  });
  //endregion state

  //region event
  /// Login Event Tests
  group("LoginEvent", () {
    test("supports value comparisons", () {
      expect(const LoginFormSubmitted(username: "test", password: "test"), const LoginFormSubmitted(username: "test", password: "test"));
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
      expect(LoginBloc(loginRepository: repository).state, const LoginState());
    });

    group("LoginFormSubmitted", () {
      const input = mockUserJWTPayload;
      Future<JWTToken> output = Future<JWTToken>.value(mockJWTTokenPayload);
      method() => repository.authenticate(input);

      final event = LoginFormSubmitted(username: input.username!, password: input.password!);

      final loadingState = LoginLoadingState(username: input.username!, password: input.password!);
      final successState = LoginLoadedState(username: input.username!, password: input.password!);
      const failureState = LoginErrorState(message: "Login API Error: Operation Unauthorized");
      const failure2State = LoginErrorState(message: "Login Error: Access Token is null");

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];
      final states2Failure = [loadingState, failure2State];

      blocTest<LoginBloc, LoginState>(
        "emits [loading, success] when login is successful",
        setUp: () => when(method()).thenAnswer((_) async => output),
        build: () => LoginBloc(loginRepository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
        verify: (_) => verify(method()).called(1),
      );

      blocTest<LoginBloc, LoginState>(
        "emits [loading, failure] when invalid operation input failed",
        setUp: () => when(method()).thenThrow(UnauthorizedException()),
        build: () => LoginBloc(loginRepository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
        verify: (_) => verify(method()).called(1),
      );

      blocTest<LoginBloc, LoginState>(
        "emits [loading, failure] when invalid input then failed",
        setUp: () => when(method()).thenAnswer((_) async => const JWTToken(idToken: null)),
        build: () => LoginBloc(loginRepository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => states2Failure,
        verify: (_) => verify(method()).called(1),
      );
    });
  });

//endregion bloc
}
