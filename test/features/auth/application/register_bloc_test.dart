import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/register_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
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
  Result<UserEntity>? registerResult;

  @override
  Future<Result<void>> changePassword(PasswordChangeDTO passwordChangeDTO) async => const Success(null);

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<UserEntity>> getAccount() async => const Success(UserEntity());

  @override
  Future<Result<UserEntity>> register(UserEntity newUser) async {
    return registerResult ?? Success(newUser);
  }

  @override
  Future<Result<void>> resetPassword(String mailAddress) async => const Success(null);

  @override
  Future<Result<UserEntity>> update(UserEntity user) async => Success(user);
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

    test("RegisterInitialState", () {
      expect(const RegisterInitialState(), const RegisterInitialState());
      expect(const RegisterInitialState().props, const <Object?>[]);
    });

    test("RegisterLoadingState", () {
      expect(const RegisterLoadingState(), const RegisterLoadingState());
      expect(const RegisterLoadingState().props, const <Object?>[]);
    });

    test("RegisterCompletedState", () {
      expect(const RegisterCompletedState(user: user), const RegisterCompletedState(user: user));
      expect(const RegisterCompletedState(user: user).props, const <Object?>[user]);
    });

    test("RegisterErrorState", () {
      expect(const RegisterErrorState(message: "Register Error"), const RegisterErrorState(message: "Register Error"));
      expect(const RegisterErrorState(message: "Register Error").props, const <Object?>["Register Error"]);
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
      expect(RegisterBloc(registerAccountUseCase: RegisterAccountUseCase(repository)).state, initialState);
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
        setUp: () => repository.registerResult = const Success(input),
        build: () => RegisterBloc(registerAccountUseCase: RegisterAccountUseCase(repository)),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );

      blocTest<RegisterBloc, RegisterState>(
        "emits [loading, failure] when exception occurs",
        setUp: () => repository.registerResult = const Failure(UnknownError("Register Error")),
        build: () => RegisterBloc(registerAccountUseCase: RegisterAccountUseCase(repository)),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );

      blocTest<RegisterBloc, RegisterState>(
        "emits [loading, failure] when response is failure",
        setUp: () => repository.registerResult = const Failure(ValidationError("Register Error")),
        build: () => RegisterBloc(registerAccountUseCase: RegisterAccountUseCase(repository)),
        act: (bloc) => bloc..add(event),
        expect: () => statesFailure,
      );
    });
  });

  //endregion bloc
}
