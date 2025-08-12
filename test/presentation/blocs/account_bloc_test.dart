import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../fake/user_data.dart';
import '../../test_utils.dart';
import 'account_bloc_test.mocks.dart';

/// BLoc Test for AccountBloc
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
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });
  //endregion main setup

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
      final user = User(
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
    late AccountRepository repository;
    late AccountBloc bloc;

    setUp(() {
      repository = MockAccountRepository();
      bloc = AccountBloc(repository: repository);
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
          when(repository.getAccount()).thenAnswer((_) async => mockUserFullPayload);
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
          when(repository.getAccount()).thenThrow(Exception("error"));
          return bloc;
        },
        act: (bloc) => bloc.add(const AccountFetchEvent()),
        expect: () => [
          const AccountState(status: AccountStatus.loading),
          const AccountState(status: AccountStatus.failure),
        ],
      );
    });
  });
  //endregion bloc
}
