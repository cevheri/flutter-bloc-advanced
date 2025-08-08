import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/change_password/bloc/change_password_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../fake/user_data.dart';
import '../../test_utils.dart';
import 'account_bloc_test.mocks.dart';

/// BLoc Test for UserBloc
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
      Future<int> output = Future.value(HttpStatus.ok);
      method() => repository.changePassword(input);

      final event = ChangePasswordChanged(currentPassword: input.currentPassword!, newPassword: input.newPassword!);
      const loadingState = ChangePasswordState(status: ChangePasswordStatus.loading);
      const successState = ChangePasswordState(status: ChangePasswordStatus.success);
      const errorState = ChangePasswordState(status: ChangePasswordStatus.failure);

      const statesSuccess = [loadingState, successState];
      const statesError = [loadingState, errorState];

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [loading, success] when ChangePasswordChanged is added",
        setUp: () => when(method()).thenAnswer((_) => Future.value(output)),
        build: () => ChangePasswordBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
        verify: (_) => verify(method()).called(1),
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [loading, error] when ChangePasswordChanged is added",
        setUp: () => when(method()).thenThrow(BadRequestException()),
        build: () => ChangePasswordBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesError,
        verify: (_) => verify(method()).called(1),
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [loading error400] when repository return 400",
        setUp: () => when(method()).thenAnswer((_) => Future.value(400)),
        build: () => ChangePasswordBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesError,
        verify: (_) => verify(method()).called(1),
      );
    });
  });
  //endregion bloc
}
