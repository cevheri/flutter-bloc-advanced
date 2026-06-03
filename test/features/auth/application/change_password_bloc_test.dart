import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/change_password_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/application/change_password_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/fake_data.dart';
import '../../../mocks/mock_classes.dart';

/// BLoc Test for ChangePasswordBloc
///
/// Tests:
/// 1. State test
/// 2. Event test
/// 3. Bloc test

void main() {
  //region main setup
  late AccountRepository repository;

  setUpAll(() {
    repository = MockAccountRepository();
  });
  //endregion main setup

  //region state
  group("ChangePasswordState", () {
    test("ChangePasswordInitialState equals", () {
      expect(const ChangePasswordInitialState(), const ChangePasswordInitialState());
      expect(const ChangePasswordInitialState().props, const <Object?>[]);
    });

    test("ChangePasswordLoadingState equals", () {
      expect(const ChangePasswordLoadingState(), const ChangePasswordLoadingState());
      expect(const ChangePasswordLoadingState().props, const <Object?>[]);
    });

    test("ChangePasswordSuccessState equals", () {
      expect(const ChangePasswordSuccessState(), const ChangePasswordSuccessState());
      expect(const ChangePasswordSuccessState().props, const <Object?>[]);
    });

    test("ChangePasswordFailureState equals", () {
      expect(
        const ChangePasswordFailureState(errorMessage: "boom"),
        const ChangePasswordFailureState(errorMessage: "boom"),
      );
      expect(const ChangePasswordFailureState(errorMessage: "boom").props, const <Object?>["boom"]);
    });

    test("different variants are not equal", () {
      expect(const ChangePasswordLoadingState(), isNot(const ChangePasswordInitialState()));
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
    test("initial state is ChangePasswordInitialState", () {
      expect(
        ChangePasswordBloc(changePasswordUseCase: ChangePasswordUseCase(repository)).state,
        const ChangePasswordInitialState(),
      );
    });

    group("ChangePasswordChanged", () {
      const input = mockPasswordChangePayload;
      method() => repository.changePassword(input);

      final event = ChangePasswordChanged(currentPassword: input.currentPassword!, newPassword: input.newPassword!);
      const loadingState = ChangePasswordLoadingState();
      const successState = ChangePasswordSuccessState();

      const statesSuccess = [loadingState, successState];

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [loading, success] when ChangePasswordChanged is added",
        setUp: () => when(method).thenAnswer((_) async => const Success<void>(null)),
        build: () => ChangePasswordBloc(changePasswordUseCase: ChangePasswordUseCase(repository)),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
        verify: (_) => verify(method).called(1),
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [loading, error] when ChangePasswordChanged is added and returns Failure",
        setUp: () => when(method).thenAnswer((_) async => const Failure<void>(ServerError('Change password failed'))),
        build: () => ChangePasswordBloc(changePasswordUseCase: ChangePasswordUseCase(repository)),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, const ChangePasswordFailureState(errorMessage: 'Change password failed')],
        verify: (_) => verify(method).called(1),
      );

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [loading, error] when repository returns Failure with ValidationError",
        setUp: () => when(method).thenAnswer((_) async => const Failure<void>(ValidationError('Invalid password'))),
        build: () => ChangePasswordBloc(changePasswordUseCase: ChangePasswordUseCase(repository)),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, const ChangePasswordFailureState(errorMessage: 'Invalid password')],
        verify: (_) => verify(method).called(1),
      );
    });
  });
  //endregion bloc
}
