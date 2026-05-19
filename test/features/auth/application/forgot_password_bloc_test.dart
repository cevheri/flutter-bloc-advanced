import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/reset_password_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/application/forgot_password_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';
import '../../../test_utils.dart';

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
    test("ForgotPasswordInitialState", () {
      expect(const ForgotPasswordInitialState(), const ForgotPasswordInitialState());
      expect(const ForgotPasswordInitialState().props, const <Object?>[]);
    });

    test("ForgotPasswordLoadingState", () {
      expect(const ForgotPasswordLoadingState(), const ForgotPasswordLoadingState());
      expect(const ForgotPasswordLoadingState().props, const <Object?>[]);
    });

    test("ForgotPasswordCompletedState", () {
      expect(
        const ForgotPasswordCompletedState(email: 'test@example.com'),
        const ForgotPasswordCompletedState(email: 'test@example.com'),
      );
      expect(const ForgotPasswordCompletedState(email: 'test@example.com').props, const <Object?>['test@example.com']);
    });

    test("ForgotPasswordErrorState", () {
      expect(
        const ForgotPasswordErrorState(email: 'test@example.com', errorMessage: 'boom'),
        const ForgotPasswordErrorState(email: 'test@example.com', errorMessage: 'boom'),
      );
      expect(const ForgotPasswordErrorState(email: 'test@example.com', errorMessage: 'boom').props, const <Object?>[
        'test@example.com',
        'boom',
      ]);
    });

    test("initial bloc state is ForgotPasswordInitialState", () {
      expect(
        ForgotPasswordBloc(resetPasswordUseCase: ResetPasswordUseCase(repository)).state,
        const ForgotPasswordInitialState(),
      );
    });
  });
  //endregion state

  //region bloc
  group("ForgotPassword Bloc Test", () {
    const email = "test@test.com";
    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits [Loading, Completed] when resetPassword is successful',
      setUp: () => when(() => repository.resetPassword(email)).thenAnswer((_) async => const Success<void>(null)),
      build: () => ForgotPasswordBloc(resetPasswordUseCase: ResetPasswordUseCase(repository)),
      act: (bloc) => bloc..add(const ForgotPasswordEmailChanged(email: email)),
      expect: () => [const ForgotPasswordLoadingState(), const ForgotPasswordCompletedState(email: email)],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits [Loading, Error] when resetPassword returns Failure',
      setUp: () => when(
        () => repository.resetPassword(email),
      ).thenAnswer((_) async => const Failure<void>(ServerError('Reset failed'))),
      build: () => ForgotPasswordBloc(resetPasswordUseCase: ResetPasswordUseCase(repository)),
      act: (bloc) => bloc..add(const ForgotPasswordEmailChanged(email: email)),
      expect: () => [
        const ForgotPasswordLoadingState(),
        const ForgotPasswordErrorState(email: email, errorMessage: 'Reset failed'),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'emits [Loading, Error] when resetPassword returns ValidationError',
      setUp: () => when(
        () => repository.resetPassword('invalid-email'),
      ).thenAnswer((_) async => const Failure<void>(ValidationError('Invalid email'))),
      build: () => ForgotPasswordBloc(resetPasswordUseCase: ResetPasswordUseCase(repository)),
      act: (bloc) => bloc..add(const ForgotPasswordEmailChanged(email: 'invalid-email')),
      expect: () => [
        const ForgotPasswordLoadingState(),
        const ForgotPasswordErrorState(email: 'invalid-email', errorMessage: 'Invalid email'),
      ],
    );
  });
  //endregion bloc
}
