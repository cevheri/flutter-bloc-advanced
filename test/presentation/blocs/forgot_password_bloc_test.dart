import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_utils.dart';
import 'forgot_password_bloc_test.mocks.dart';

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
  //endregion setup

  //region event
  group('ForgotPasswordEvent Tests', () {
    test('ForgotPasswordEmailChanged should correctly store the email', () {
      // Arrange
      const email = 'test@example.com';

      // Act
      const event = ForgotPasswordEmailChanged(email: email);

      // Assert
      expect(event.email, email);
    });

    test('ForgotPasswordEmailChanged should be equatable', () {
      // Arrange
      const email = 'test@example.com';
      // Act
      const event = ForgotPasswordEmailChanged(email: email);
      // Assert
      expect(event, equals(event));
    });

    // Props and Stringify Test
    test('ForgotPasswordEvent should have props and stringify', () {
      // Arrange
      const email = 'test@example.com';
      const event = ForgotPasswordEmailChanged(email: email);

      // Assert
      expect(event.stringify, true);
      expect(event.props, [email]);
      expect(event.toString(), contains(email));
    });
  });
  //endregion event

  //region state
  /// ForgotPassword State Tests
  group('ForgotPassword State Tests', () {
    //ForgotPasswordState
    test("supports value comparisons", () {
      expect(const ForgotPasswordState(), const ForgotPasswordState());
      const state = ForgotPasswordState(status: ForgotPasswordStatus.initial);
      expect(const ForgotPasswordState(), state);
    });

    //ForgotPasswordState İnitial Test
    test('initial state is ForgotPasswordState', () {
      expect(
        ForgotPasswordBloc(repository: repository).state,
        const ForgotPasswordState(status: ForgotPasswordStatus.initial),
      );
    });

    //ForgotPasswordInitialState Test
    test("ForgotPasswordInitialState", () {
      expect(const ForgotPasswordInitialState(), const ForgotPasswordInitialState());
    });

    //ForgotPasswordCompletedState Test
    test("ForgotPasswordCompletedState", () {
      expect(const ForgotPasswordCompletedState(), const ForgotPasswordCompletedState());
    });

    // ForgotPasswordErrorState Test
    test("ForgotPasswordErrorState", () {
      expect(
        const ForgotPasswordErrorState(message: "Reset Password Error"),
        const ForgotPasswordErrorState(message: "Reset Password Error"),
      );
      //expect(const ForgotPasswordErrorState(message: "Reset Password Error", ["Reset Password Error"]);
    });

    test("copyWith retains the same values if no arguments are provided", () {
      const state = ForgotPasswordState(status: ForgotPasswordStatus.failure, email: "test@example.com");
      expect(state.copyWith(), state);
    });

    test("props", () {
      expect(const ForgotPasswordState(status: ForgotPasswordStatus.initial, email: 'test@example.com').props, [
        ForgotPasswordStatus.initial,
        "test@example.com",
      ]);
    });

    test("initial state is ForgotPasswordState", () {
      expect(
        ForgotPasswordBloc(repository: repository).state,
        const ForgotPasswordState(status: ForgotPasswordStatus.initial),
      );
    });
  });
  //endregion state

  //region bloc
  group("ForgotPassword Bloc Test", () {
    const email = "test@test.com";
    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits [ForgotPasswordLoadingState, ForgotPasswordCompletedState] when resetPassword is successful',
      setUp: () => when(repository.resetPassword(email)).thenAnswer((_) => Future.value(HttpStatus.ok)),
      build: () => ForgotPasswordBloc(repository: repository),
      act: (bloc) => bloc..add(const ForgotPasswordEmailChanged(email: email)),
      expect: () => [
        const ForgotPasswordState(status: ForgotPasswordStatus.loading),
        const ForgotPasswordState(status: ForgotPasswordStatus.success, email: email),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits [ForgotPasswordLoadingState, ForgotPasswordErrorState] when resetPassword fails',
      setUp: () => when(repository.resetPassword(email)).thenAnswer((_) => Future.value(HttpStatus.badRequest)),
      build: () => ForgotPasswordBloc(repository: repository),
      act: (bloc) => bloc..add(const ForgotPasswordEmailChanged(email: email)),
      expect: () => [
        const ForgotPasswordState(status: ForgotPasswordStatus.loading),
        const ForgotPasswordState(status: ForgotPasswordStatus.failure),
      ],
    );
    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits [ForgotPasswordLoadingState, ForgotPasswordErrorState] when invalid-email then resetPassword fails',
      setUp: () => when(repository.resetPassword(email)).thenThrow(BadRequestException()),
      build: () => ForgotPasswordBloc(repository: repository),
      act: (bloc) => bloc..add(const ForgotPasswordEmailChanged(email: 'invalid-email')),
      expect: () => [
        const ForgotPasswordState(status: ForgotPasswordStatus.loading),
        const ForgotPasswordState(status: ForgotPasswordStatus.failure),
      ],
    );
  });
  //endregion bloc
}
