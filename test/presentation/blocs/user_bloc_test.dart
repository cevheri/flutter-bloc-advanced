import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../fake/user_data.dart';
import '../../init.dart';
import 'user_bloc_test.mocks.dart';

/// BLoc Test for AccountBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 1.1. Supports value comparisons <p>
/// 1.2. CopyWith retains the same values if no arguments are provided <p>
/// 1.3. CopyWith replaces non-null parameters <p>
/// 2. Event test <p>
/// 3. Bloc test <p>

@GenerateMocks([UserRepository])
void main() {
  //region main setup
  setUpAll(() {
    initBlocDependencies();
  });
  //endregion main setup

  //region state
  /// User State Tests
  group("UserState", () {
    test("supports value comparisons", () {
      expect(
        const UserState(),
        const UserState(),
      );
    });

    test("copyWith retains the same values if no arguments are provided", () {
      const state = UserState(
        user: null,
        status: UserStatus.initial,
      );
      expect(state.copyWith(), state);
    });

    test("copyWith replaces non-null parameters", () {
      const state = UserState(
        user: null,
        status: UserStatus.initial,
      );
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
        state.copyWith(user: user, status: UserStatus.success),
        UserState(user: user, status: UserStatus.success),
      );
    });
  });
  //endregion state

  //region event
  /// User Event Tests
  group("UserEvent", () {
    test("supports value comparisons", () {
      expect(const UserEvent(), const UserEvent());
      expect(const UserSearch(0, 10, "ROLE_USER", "test"), const UserSearch(0, 10, "ROLE_USER", "test"));
      expect(UserCreate(user: mockUserFullPayload), UserCreate(user: mockUserFullPayload));
      expect(UserUpdate(user: mockUserFullPayload), UserUpdate(user: mockUserFullPayload));
      expect(UserEdit(user: mockUserFullPayload), UserEdit(user: mockUserFullPayload));
      expect(UserList(), UserList());
    });

    test("props returns []", () {
      expect(const UserEvent().props, []);
    });

    test("toString returns correct value", () {
      expect(const UserEvent().toString(), "UserEvent()");
    });
  });
  //endregion event

  //region bloc
  /// User Bloc Tests
  group("UserBloc", () {
    late UserRepository repository;
    late UserBloc bloc;

    setUp(() {
      repository = MockUserRepository();
      bloc = UserBloc(userRepository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test("initial state is UserState", () {
      expect(bloc.state, const UserState());
    });

    group("on UserLoad", () {
      blocTest<UserBloc, UserState>(
        "emits [loading, success] when UserLoad is added and getUser succeeds",
        build: () {
          when(repository.getUsers()).thenAnswer((_) async => [mockUserFullPayload]);
          when(repository.listUser(0, 100)).thenAnswer((_) async => [mockUserFullPayload]);
          return bloc;
        },
        act: (bloc) => bloc.add(UserList()),
        expect: () => [
          UserListInitialState(),
          UserListSuccessState(userList: [mockUserFullPayload]),
        ],
      );

      blocTest<UserBloc, UserState>(
        "emits [loading, failure] when UserLoad is added and getUser fails",
        build: () {
          when(repository.getUsers()).thenThrow(Exception("error"));
          when(repository.listUser(0, 100)).thenThrow(Exception("error"));
          return bloc;
        },
        act: (bloc) => bloc.add(UserList()),
        expect: () => [
          UserListInitialState(),
          UserListFailureState(message: "error"),
        ],
      );
    });
  });
//endregion bloc
}
