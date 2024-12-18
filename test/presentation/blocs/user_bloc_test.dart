import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../fake/user_data.dart';
import '../../test_utils.dart';
import 'user_bloc_test.mocks.dart';

/// BLoc Test for UserBloc
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
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });
  //endregion main setup

  //region state
  /// User State Tests
  group("UserState", () {
    test("supports value comparisons", () {
      expect(const UserState(), const UserState());
    });

    test("copyWith retains the same values if no arguments are provided", () {
      const state = UserState(user: null, status: UserStatus.initial);
      expect(state.copyWith(), state);
    });

    test("copyWith replaces non-null parameters", () {
      const state = UserState(user: null, status: UserStatus.initial);
      final user = mockUserFullPayload;
      expect(
        state.copyWith(user: user, status: UserStatus.success),
        UserState(user: user, status: UserStatus.success),
      );
    });
  });

  group("UserLoadSuccessState", () {
    test("supports value comparisons", () {
      final user = mockUserFullPayload;
      expect(UserLoadSuccessState(userLoadSuccess: user), UserLoadSuccessState(userLoadSuccess: user));
    });
  });

  group("UserEditSuccessState", () {
    test("supports value comparisons", () {
      final user = mockUserFullPayload;
      expect(UserEditSuccessState(userEditSuccess: user), UserEditSuccessState(userEditSuccess: user));
    });
  });

  group("UserSearchSuccessState", () {
    test("supports value comparisons", () {
      final userList = [mockUserFullPayload];
      expect(UserSearchSuccessState(userList: userList), UserSearchSuccessState(userList: userList));
    });
  });

  group("UserLoadFailureState", () {
    test("supports value comparisons", () {
      const message = "Error loading user";
      expect(const UserLoadFailureState(message: message), const UserLoadFailureState(message: message));
    });
  });

  group("UserEditFailureState", () {
    test("supports value comparisons", () {
      const message = "Error editing user";
      expect(const UserEditFailureState(message: message), const UserEditFailureState(message: message));
    });
  });

  group("UserSearchFailureState", () {
    test("supports value comparisons", () {
      const message = "Error searching user";
      expect(const UserSearchFailureState(message: message), const UserSearchFailureState(message: message));
    });
  });

  group("UserListSuccessState", () {
    test("supports value comparisons", () {
      final userList = [mockUserFullPayload];
      expect(
        UserListSuccessState(userList: userList),
        UserListSuccessState(userList: userList),
      );
    });
  });

  group("UserListFailureState", () {
    test("supports value comparisons", () {
      const message = "Error loading user list";
      expect(const UserListFailureState(message: message), const UserListFailureState(message: message));
    });
  });
  //endregion state

  //region event
  /// User Event Tests
  group("UserEvent", () {
    test("supports value comparisons", () {
      expect(const UserEvent(), const UserEvent());
      expect(const UserSearch(0, 10, "ROLE_USER", "test"), const UserSearch(0, 10, "ROLE_USER", "test"));
      //TODO UserInit and UserSubmit will be added
      // expect(UserCreate(user: mockUserFullPayload), UserCreate(user: mockUserFullPayload));
      // expect(UserSaveEvent(user: mockUserFullPayload), UserSaveEvent(user: mockUserFullPayload));
      // expect(UserEditEvent(user: mockUserFullPayload), UserEditEvent(user: mockUserFullPayload));
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
      bloc = UserBloc(repository: repository);
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
          const UserListInitialState(),
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
        expect: () => [const UserListInitialState(), const UserListFailureState(message: "error")],
      );
    });

    //TODO user create will be added
    // group("on UserCreate", () {
    //
    //   blocTest<UserBloc, UserState>(
    //     "emits [UserInitialState, UserLoadSuccessState] when UserCreate is added and createUser succeeds",
    //     build: () {
    //       when(repository.create(mockUserFullPayload)).thenAnswer((_) async => mockUserFullPayload);
    //       return bloc;
    //     },
    //     act: (bloc) => bloc.add(UserCreate(user: mockUserFullPayload)),
    //     expect: () => [
    //       const UserInitialState(),
    //       UserLoadSuccessState(userLoadSuccess: mockUserFullPayload),
    //     ],
    //   );
    //
    //   blocTest<UserBloc, UserState>(
    //     "emits [UserInitialState, UserLoadFailureState] when UserCreate is added and createUser fails",
    //     build: () {
    //       when(repository.create(mockUserFullPayload)).thenThrow(Exception("error"));
    //       return bloc;
    //     },
    //     act: (bloc) => bloc.add(UserCreate(user: mockUserFullPayload)),
    //     expect: () => [const UserInitialState(), const UserLoadFailureState(message: "Exception: error")],
    //   );
    // });

    group("on UserSearch", () {
      blocTest<UserBloc, UserState>(
          "emits [UserFindInitialState, UserSearchSuccessState] when UserSearch is added and findUserByAuthorities succeeds",
          build: () {
            when(repository.findUserByAuthority(0, 10, "ROLE_USER")).thenAnswer((_) async => [mockUserFullPayload]);
            return bloc;
          },
          act: (bloc) => bloc.add(const UserSearch(0, 10, "ROLE_USER", "")),
          expect: () => [
                const UserFindInitialState(),
                UserSearchSuccessState(userList: [mockUserFullPayload])
              ]);

      blocTest<UserBloc, UserState>("emits [UserFindInitialState, UserSearchSuccessState] when UserSearch is added and findUserByName succeeds",
          build: () {
            when(repository.findUserByName(0, 10, "test", "ROLE_USER")).thenAnswer((_) async => [mockUserFullPayload]);
            return bloc;
          },
          act: (bloc) => bloc.add(const UserSearch(0, 10, "ROLE_USER", "test")),
          expect: () => [
                const UserFindInitialState(),
                UserSearchSuccessState(userList: [mockUserFullPayload])
              ]);

      blocTest<UserBloc, UserState>(
        "emits [UserFindInitialState, UserSearchFailureState] when UserSearch is added and findUserByAuthorities fails",
        build: () {
          when(repository.findUserByAuthority(0, 10, "ROLE_USER")).thenThrow(Exception("error"));
          return bloc;
        },
        act: (bloc) => bloc.add(const UserSearch(0, 10, "ROLE_USER", "")),
        expect: () => [const UserFindInitialState(), const UserSearchFailureState(message: "Exception: error")],
      );

      blocTest<UserBloc, UserState>(
        "emits [UserFindInitialState, UserSearchFailureState] when UserSearch is added and findUserByName fails",
        build: () {
          when(repository.findUserByName(0, 10, "test", "ROLE_USER")).thenThrow(Exception("error"));
          return bloc;
        },
        act: (bloc) => bloc.add(const UserSearch(0, 10, "ROLE_USER", "test")),
        expect: () => [const UserFindInitialState(), const UserSearchFailureState(message: "Exception: error")],
      );
    });

    //TODO user edit will be added
    // group("on UserEdit", () {
    //   blocTest<UserBloc, UserState>(
    //     "emits [UserEditInitialState, UserEditSuccessState] when UserEdit is added and updateUser succeeds",
    //     build: () {
    //       when(repository.update(mockUserFullPayload)).thenAnswer((_) async => mockUserFullPayload);
    //       return bloc;
    //     },
    //     act: (bloc) => bloc.add(UserEditEvent(user: mockUserFullPayload)),
    //     expect: () => [const UserEditInitialState(), UserEditSuccessState(userEditSuccess: mockUserFullPayload)],
    //   );
    //
    //   blocTest<UserBloc, UserState>(
    //     "emits [UserEditInitialState, UserEditFailureState] when UserEdit is added and updateUser fails",
    //     build: () {
    //       when(repository.update(mockUserFullPayload)).thenThrow(Exception("error"));
    //       return bloc;
    //     },
    //     act: (bloc) => bloc.add(UserEditEvent(user: mockUserFullPayload)),
    //     expect: () => [const UserEditInitialState(), const UserEditFailureState(message: "Exception: error")],
    //   );
    // });
  });
//endregion bloc
}
