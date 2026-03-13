import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/application/change_password_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/fake_data.dart';
import '../../../mocks/mock_classes.dart';
import '../../../test_utils.dart';

/// BLoc Test for UserBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 1.1. Supports value comparisons <p>
/// 1.2. CopyWith retains the same values if no arguments are provided <p>
/// 1.3. CopyWith replaces non-null parameters <p>
/// 2. Event test <p>
/// 3. Bloc test <p>

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
  /// ChangePasswordState State Tests
  group("ChangePasswordState", () {
    //ChangePasswordEvent and prob event test
    test("ChangePasswordState", () {
      expect(const ChangePasswordState(), const ChangePasswordState());
    });

    // ChangePasswordInitialState prob state test
    test("ChangePasswordInitialState", () {
      expect(const ChangePasswordInitialState(), const ChangePasswordInitialState());
    });

    // ChangePasswordPasswordCompletedState
    test("ChangePasswordPasswordCompletedState", () {
      expect(const ChangePasswordCompletedState(), const ChangePasswordCompletedState());
    });

    // ChangePasswordPasswordErrorState
    test("ChangePasswordPasswordErrorState", () {
      expect(const ChangePasswordErrorState(message: ""), const ChangePasswordErrorState(message: ""));
    });

    test("copyWith state", () {
      expect(const ChangePasswordState().copyWith(), const ChangePasswordState());
    });
    test("copyWith initialState", () {
      expect(
        const ChangePasswordInitialState().copyWith(),
        const ChangePasswordState(status: ChangePasswordStatus.initial),
      );
    });
    test("copyWith loadingState", () {
      expect(
        const ChangePasswordLoadingState().copyWith(),
        const ChangePasswordState(status: ChangePasswordStatus.loading),
      );
    });
    test("copyWith passwordCompletedState", () {
      expect(
        const ChangePasswordCompletedState().copyWith(),
        const ChangePasswordState(status: ChangePasswordStatus.success),
      );
    });
    test("copyWith passwordErrorState", () {
      expect(
        const ChangePasswordErrorState(message: "").copyWith(),
        const ChangePasswordState(status: ChangePasswordStatus.failure),
      );
    });
  });
  //endregion state

  //region event
  /// ChangePasswordEvent Tests
  group("ChangePasswordEvent", () {
    // ChangePasswordChanged
    test("ChangePasswordChanged", () {
      expect(
        const ChangePasswordChanged(currentPassword: "123", newPassword: "123"),
        const ChangePasswordChanged(currentPassword: "123", newPassword: "123"),
      );
    });
    test("TogglePasswordVisibility", () {
      expect(const TogglePasswordVisibility(), const TogglePasswordVisibility());
    });
  });
  //endregion event

  //region bloc
  /// ChangePasswordBloc Tests
  group("ChangePasswordBloc", () {
    test("initial state is LoginState", () {
      expect(
        ChangePasswordBloc(repository: repository).state,
        const ChangePasswordState(status: ChangePasswordStatus.initial),
      );
    });

    group("ChangePasswordChanged", () {
      const input = mockPasswordChangePayload;
      method() => repository.changePassword(input);

      final event = ChangePasswordChanged(currentPassword: input.currentPassword!, newPassword: input.newPassword!);
      const loadingState = ChangePasswordState(status: ChangePasswordStatus.loading);
      const successState = ChangePasswordState(status: ChangePasswordStatus.success);
      const errorState = ChangePasswordState(status: ChangePasswordStatus.failure);

      const statesSuccess = [loadingState, successState];
      const statesError = [loadingState, errorState];

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [loading, success] when ChangePasswordChanged is added",
        setUp: () => when(method).thenAnswer((_) async => const Success<void>(null)),
        build: () => ChangePasswordBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
        verify: (_) => verify(method).called(1),
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [loading, error] when ChangePasswordChanged is added and returns Failure",
        setUp: () => when(method).thenAnswer((_) async => const Failure<void>(ServerError('Change password failed'))),
        build: () => ChangePasswordBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesError,
        verify: (_) => verify(method).called(1),
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [loading, error] when repository returns Failure with ValidationError",
        setUp: () => when(method).thenAnswer((_) async => const Failure<void>(ValidationError('Invalid password'))),
        build: () => ChangePasswordBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesError,
        verify: (_) => verify(method).called(1),
      );
    });
  });
  //endregion bloc
}
