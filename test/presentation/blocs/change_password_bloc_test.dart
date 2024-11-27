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
      expect( ChangePasswordInitialState(),  ChangePasswordInitialState());
    });

    // ChangePasswordPasswordCompletedState
    test("ChangePasswordPasswordCompletedState", () {
      expect( ChangePasswordPasswordCompletedState(),  ChangePasswordPasswordCompletedState());
    });

    // ChangePasswordPasswordErrorState
    test("ChangePasswordPasswordErrorState", () {
      expect(const ChangePasswordPasswordErrorState(message: ""),const ChangePasswordPasswordErrorState(message: ""));
    });
    //ChangePasswordEvent
  });
  //endregion state

  //region bloc
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

  /// ChangePasswordBloc Tests
  group("ChangePasswordBloc", () {
    test("initial state is LoginState", () {
      expect(ChangePasswordBloc(repository: repository).state, const ChangePasswordState());
    });

    group("ChangePasswordChanged", () {
      const input = mockPasswordChangePayload;
      Future<int> output = Future.value(HttpStatus.ok);
      method() => repository.changePassword(input);

      final event = ChangePasswordChanged(currentPassword: input.currentPassword!, newPassword: input.newPassword!);
      var successState = ChangePasswordPasswordCompletedState();
      const errorState = ChangePasswordPasswordErrorState(message: 'Hata oluştu');

      final statesSuccess = [ ChangePasswordInitialState(), successState];
      final statesError = [ ChangePasswordInitialState(), errorState];

      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [ChangePasswordInitialState, ChangePasswordPasswordCompletedState] when ChangePasswordChanged is added",
        setUp: () => when(method()).thenAnswer((_) => Future.value(output)),
        build: () => ChangePasswordBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
        verify: (_) => verify(method()).called(1),
      );


      blocTest<ChangePasswordBloc, ChangePasswordState>(
        "emits [ChangePasswordInitialState, ChangePasswordPasswordErrorState] when ChangePasswordChanged is added",
        setUp: () => when(method()).thenThrow(BadRequestException("hata")),
        build: () => ChangePasswordBloc(repository: repository),
        act: (bloc) => bloc..add(event),
        expect: () => statesError,
        verify: (_) => verify(method()).called(1),
      );
    });
  });
  //endregion bloc
}
