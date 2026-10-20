import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/update_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/fake_data.dart';

/// BLoc Test for AccountBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 1.1. Supports value comparisons <p>
/// 1.2. CopyWith retains the same values if no arguments are provided <p>
/// 1.3. CopyWith replaces non-null parameters <p>
/// 2. Event test <p>
/// 3. Bloc test <p>

class _FakeAccountRepository implements IAccountRepository {
  UserEntity? account;
  AppError? failure;

  /// When set, getAccount and update answer only once it completes, like a slow network.
  Completer<void>? answer;

  @override
  Future<Result<void>> changePassword(PasswordChangeDTO passwordChangeDTO) async => const Success(null);

  @override
  Future<Result<UserEntity>> getAccount() async {
    await answer?.future;
    if (failure != null) return Failure(failure!);
    return Success(account!);
  }

  @override
  Future<Result<UserEntity>> register(UserEntity newUser) async {
    if (failure != null) return Failure(failure!);
    return Success(account ?? newUser);
  }

  @override
  Future<Result<void>> resetPassword(String mailAddress) async => const Success(null);

  @override
  Future<Result<UserEntity>> update(UserEntity user) async {
    await answer?.future;
    if (failure != null) return Failure(failure!);
    return Success(account ?? user);
  }
}

void main() {
  //region state
  /// Account State Tests
  group("AccountState", () {
    test("supports value comparisons", () {
      expect(const AccountState(), const AccountState());
    });

    test("copyWith retains the same values if no arguments are provided", () {
      const state = AccountState(data: null, status: AccountStatus.initial);
      expect(state.copyWith(), state);
    });

    test("copyWith replaces non-null parameters", () {
      const state = AccountState(data: null, status: AccountStatus.initial);
      final user = UserEntity(
        id: "1",
        login: "test_login",
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        activated: true,
        langKey: "en",
        createdBy: "admin",
        createdDate: DateTime(2024, 1, 1),
        lastModifiedBy: "admin",
        lastModifiedDate: DateTime(2024, 1, 1),
        authorities: const ["test"],
      );
      expect(
        state.copyWith(data: user, status: AccountStatus.success),
        AccountState(data: user, status: AccountStatus.success),
      );
    });
  });
  //endregion state

  //region event
  /// Account Event Tests
  group("AccountEvent", () {
    test("supports value comparisons", () {
      expect(const AccountFetchEvent(), const AccountFetchEvent());
    });

    test("props returns []", () {
      expect(const AccountEvent().props, []);
      expect(const AccountFetchEvent().props, []);
    });

    test("toString returns correct value", () {
      expect(const AccountEvent().toString(), "AccountEvent()");
      expect(const AccountFetchEvent().toString(), "AccountFetchEvent()");
    });
  });
  //endregion event

  //region bloc
  /// Account Bloc Tests
  group("AccountBloc", () {
    late _FakeAccountRepository repository;
    late AccountBloc bloc;

    setUp(() {
      repository = _FakeAccountRepository();
      bloc = AccountBloc(
        getAccountUseCase: GetAccountUseCase(repository),
        updateAccountUseCase: UpdateAccountUseCase(repository),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test("initial state is AccountState", () {
      expect(bloc.state, const AccountState());
    });

    group("on AccountLoad", () {
      blocTest<AccountBloc, AccountState>(
        "emits [loading, success] when AccountLoad is added and getAccount succeeds",
        build: () {
          repository.account = mockUserFullPayload;
          return bloc;
        },
        act: (bloc) => bloc.add(const AccountFetchEvent()),
        expect: () => [
          const AccountState(status: AccountStatus.loading),
          AccountState(data: mockUserFullPayload, status: AccountStatus.success),
        ],
      );

      blocTest<AccountBloc, AccountState>(
        "emits [loading, failure] when AccountLoad is added and getAccount fails",
        build: () {
          repository.failure = const UnknownError("error");
          return bloc;
        },
        act: (bloc) => bloc.add(const AccountFetchEvent()),
        expect: () => [
          const AccountState(status: AccountStatus.loading),
          const AccountState(status: AccountStatus.failure),
        ],
      );

      // Regression: the failure dropped the code, so the page said "Failed" when the certificate matched no pin.
      blocTest<AccountBloc, AccountState>(
        "emits the code of the failed fetch",
        build: () {
          repository.failure = NetworkError('pin mismatch', code: AppErrorCode.networkCertInvalid.key);
          return bloc;
        },
        act: (bloc) => bloc.add(const AccountFetchEvent()),
        expect: () => [
          const AccountState(status: AccountStatus.loading),
          const AccountState(status: AccountStatus.failure, errorCode: AppErrorCode.networkCertInvalid),
        ],
      );

      blocTest<AccountBloc, AccountState>(
        "does not report the code of an earlier failure",
        seed: () => const AccountState(status: AccountStatus.failure, errorCode: AppErrorCode.networkCertInvalid),
        build: () {
          repository.failure = const UnknownError("error");
          return bloc;
        },
        act: (bloc) => bloc.add(const AccountFetchEvent()),
        expect: () => [
          const AccountState(status: AccountStatus.loading),
          const AccountState(status: AccountStatus.failure),
        ],
      );
    });

    group("on AccountSubmitEvent", () {
      blocTest<AccountBloc, AccountState>(
        "emits the code of the failed save and keeps the account",
        seed: () => AccountState(data: mockUserFullPayload, status: AccountStatus.success),
        build: () {
          repository.failure = NetworkError('pin mismatch', code: AppErrorCode.networkCertInvalid.key);
          return bloc;
        },
        act: (bloc) => bloc.add(AccountSubmitEvent(mockUserFullPayload)),
        expect: () => [
          AccountState(data: mockUserFullPayload, status: AccountStatus.loading),
          AccountState(
            data: mockUserFullPayload,
            status: AccountStatus.failure,
            errorCode: AppErrorCode.networkCertInvalid,
          ),
        ],
      );
    });

    // AccountBloc outlives the session; AppSessionListeners resets it when the session ends.
    group("on AccountResetEvent", () {
      blocTest<AccountBloc, AccountState>(
        "forgets the loaded account",
        build: () => bloc,
        seed: () => AccountState(data: mockUserFullPayload, status: AccountStatus.success),
        act: (bloc) => bloc.add(const AccountResetEvent()),
        expect: () => [const AccountState()],
      );

      blocTest<AccountBloc, AccountState>(
        "drops the account that a fetch still running brings back",
        build: () {
          repository
            ..account = mockUserFullPayload
            ..answer = Completer<void>();
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const AccountFetchEvent());
          await Future<void>.delayed(Duration.zero);
          bloc.add(const AccountResetEvent());
          await Future<void>.delayed(Duration.zero);
          repository.answer!.complete();
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [const AccountState(status: AccountStatus.loading), const AccountState()],
      );

      blocTest<AccountBloc, AccountState>(
        "drops the account that a save still running brings back",
        build: () {
          repository.answer = Completer<void>();
          return bloc;
        },
        act: (bloc) async {
          bloc.add(AccountSubmitEvent(mockUserFullPayload));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const AccountResetEvent());
          await Future<void>.delayed(Duration.zero);
          repository.answer!.complete();
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [const AccountState(status: AccountStatus.loading), const AccountState()],
      );
    });
  });
  //endregion bloc
}
