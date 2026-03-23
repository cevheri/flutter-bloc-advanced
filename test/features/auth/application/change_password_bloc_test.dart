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

/// BLoc Test for ChangePasswordBloc
///
/// Tests:
/// 1. State test
/// 2. Event test
/// 3. Bloc test

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
  group("ChangePasswordState", () {
    test("ChangePasswordState supports value comparisons", () {
      expect(const ChangePasswordState(), const ChangePasswordState());
    });

    test("ChangePasswordState with different status are not equal", () {
      expect(
        const ChangePasswordState(status: ChangePasswordStatus.loading),
        isNot(const ChangePasswordState(status: ChangePasswordStatus.initial)),
      );
    });

    test("copyWith retains same values if no arguments provided", () {
      expect(const ChangePasswordState().copyWith(), const ChangePasswordState());
    });

    test("copyWith replaces status", () {
      expect(
        const ChangePasswordState().copyWith(status: ChangePasswordStatus.loading),
        const ChangePasswordState(status: ChangePasswordStatus.loading),
      );
    });
  });
  //endregion state

  //region event
  group("ChangePasswordEvent", () {
    test("ChangePasswordChanged supports value comparisons", () {
      expect(
        const ChangePasswordChanged(currentPassword: "123", newPassword: "456"),
        const ChangePasswordChanged(currentPassword: "123", newPassword: "456"),
      );
    });

    test("ChangePasswordChanged with different values are not equal", () {
      expect(
        const ChangePasswordChanged(currentPassword: "123", newPassword: "456"),
        isNot(const ChangePasswordChanged(currentPassword: "123", newPassword: "789")),
      );
    });
  });
  //endregion event

  //region bloc
  group("ChangePasswordBloc", () {
    test("initial state is ChangePasswordState with initial status", () {
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
