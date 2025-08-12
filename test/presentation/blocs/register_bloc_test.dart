import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/bloc/register.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_utils.dart';
import 'register_bloc_test.mocks.dart';

/// BLoc Test for RegisterBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 1.1. Supports value comparisons <p>
/// 1.2. CopyWith retains the same values if no arguments are provided <p>
/// 1.3. CopyWith replaces non-null parameters <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
@GenerateMocks([AccountRepository])
void main() {
  //region main setup
  late AccountRepository repository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    repository = MockAccountRepository();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  //endregion main setup

  //region state
  /// Register State Tests
  group("RegisterState", () {
    const user = User(firstName: "test", lastName: "test", email: "test@test.com");
    const status = RegisterStatus.initial;

    test("supports value comparisons", () {
      expect(const RegisterState(data: user, status: status), const RegisterState(data: user, status: status));
    });

    test("RegisterInitialState", () {
      expect(const RegisterInitialState(), const RegisterInitialState());
    });

    test("RegisterLoadingState", () {
      expect(const RegisterLoadingState(), const RegisterLoadingState());
    });

    test("RegisterCompletedState", () {
      expect(const RegisterCompletedState(user: user), const RegisterCompletedState(user: user));
    });

    test("RegisterErrorState", () {
      expect(const RegisterErrorState(message: "Register Error"), const RegisterErrorState(message: "Register Error"));
    });

    test("RegisterState copyWith", () {
      expect(const RegisterState().copyWith(), const RegisterState());
      expect(const RegisterState().copyWith(data: user), const RegisterState(data: user));
      expect(const RegisterState().copyWith(status: status), const RegisterState(status: status));
    });
  });
  //endregion state

  //region event
  /// Register Event Tests
  group("RegisterEvent", () {
    const user = User(firstName: "test", lastName: "test", email: "test@test.com");

    test("RegisterFormSubmitted", () {
      expect(const RegisterFormSubmitted(data: user).props, [user]);
    });
  });
  //endregion event

  //region bloc
  /// Register Bloc Tests
  group("RegisterBloc", () {
    const initialState = RegisterInitialState();
    test("initial state is LoginState", () {
      expect(RegisterBloc(repository: repository).state, initialState);
    });

    group("LoginFormSubmitted", () {
      const input = User(firstName: "test", lastName: "test", email: "test@test.com");
      method() => repository.register(input);
      Future<User?> output = Future<User?>.value(input);

      const event = RegisterFormSubmitted(data: input);
      const loadingState = RegisterLoadingState();
      const successState = RegisterCompletedState(user: input);
      const failureState = RegisterErrorState(message: 'Register Error');

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];

      blocTest<RegisterBloc, RegisterState>(
        "emits [loading, success] when submit is successful",
        setUp: () => when(method()).thenAnswer((_) async => output),
        build: () => RegisterBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
        verify: (_) => verify(method()).called(1),
      );

      blocTest<RegisterBloc, RegisterState>(
        "emits [loading, failure] when exception occurs",
        setUp: () => when(method()).thenThrow(Exception()),
        build: () => RegisterBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
        verify: (_) => verify(method()).called(1),
      );

      blocTest<RegisterBloc, RegisterState>(
        "emits [loading, failure] when response is null",
        setUp: () => when(method()).thenAnswer((_) async => null),
        build: () => RegisterBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
        verify: (_) => verify(method()).called(1),
      );
    });
  });

  //endregion bloc
}
