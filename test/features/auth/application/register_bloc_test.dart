import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/application/register_bloc.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils.dart';

/// BLoc Test for RegisterBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 1.1. Supports value comparisons <p>
/// 1.2. CopyWith retains the same values if no arguments are provided <p>
/// 1.3. CopyWith replaces non-null parameters <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
class _FakeAccountRepository implements IAccountRepository {
  UserEntity? registerResult;
  Object? failure;

  @override
  Future<int> changePassword(passwordChangeDTO) async => 200;

  @override
  Future<bool> delete(String id) async => true;

  @override
  Future<UserEntity> getAccount() async => const UserEntity();

  @override
  Future<UserEntity?> register(UserEntity? newUser) async {
    if (failure != null) throw failure!;
    return registerResult;
  }

  @override
  Future<int> resetPassword(String mailAddress) async => 200;

  @override
  Future<UserEntity> update(UserEntity? user) async => user ?? const UserEntity();
}

void main() {
  //region main setup
  late _FakeAccountRepository repository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    repository = _FakeAccountRepository();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  //endregion main setup

  //region state
  /// Register State Tests
  group("RegisterState", () {
    const user = UserEntity(firstName: "test", lastName: "test", email: "test@test.com");
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
    const user = UserEntity(firstName: "test", lastName: "test", email: "test@test.com");

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
      const input = UserEntity(firstName: "test", lastName: "test", email: "test@test.com");
      const event = RegisterFormSubmitted(data: input);
      const loadingState = RegisterLoadingState();
      const successState = RegisterCompletedState(user: input);
      const failureState = RegisterErrorState(message: 'Register Error');

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];

      blocTest<RegisterBloc, RegisterState>(
        "emits [loading, success] when submit is successful",
        setUp: () => repository.registerResult = input,
        build: () => RegisterBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );

      blocTest<RegisterBloc, RegisterState>(
        "emits [loading, failure] when exception occurs",
        setUp: () => repository.failure = Exception(),
        build: () => RegisterBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );

      blocTest<RegisterBloc, RegisterState>(
        "emits [loading, failure] when response is null",
        setUp: () => repository.registerResult = null,
        build: () => RegisterBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );
    });
  });

  //endregion bloc
}
