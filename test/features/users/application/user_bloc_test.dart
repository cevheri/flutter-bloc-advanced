import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils.dart';

class _FakeUserRepository implements IUserRepository {
  UserEntity? retrieveResult;
  List<UserEntity> listResult = const [];
  AppError? failure;

  @override
  Future<Result<UserEntity>> create(UserEntity user) async {
    if (failure != null) return Failure(failure!);
    return Success(retrieveResult ?? user);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (failure != null) return Failure(failure!);
    return const Success(null);
  }

  @override
  Future<Result<List<UserEntity>>> list({int page = 0, int size = 10, List<String> sort = const ['id,desc']}) async {
    if (failure != null) return Failure(failure!);
    return Success(listResult);
  }

  @override
  Future<Result<List<UserEntity>>> listByAuthority(int page, int size, String authority) async {
    if (failure != null) return Failure(failure!);
    return Success(listResult);
  }

  @override
  Future<Result<List<UserEntity>>> listByNameAndRole(int page, int size, String name, String authority) async {
    if (failure != null) return Failure(failure!);
    return Success(listResult);
  }

  @override
  Future<Result<UserEntity>> retrieve(String id) async {
    if (failure != null) return Failure(failure!);
    return Success(retrieveResult!);
  }

  @override
  Future<Result<UserEntity>> retrieveByLogin(String login) async {
    if (failure != null) return Failure(failure!);
    return Success(retrieveResult!);
  }

  @override
  Future<Result<UserEntity>> update(UserEntity user) async {
    if (failure != null) return Failure(failure!);
    return Success(retrieveResult ?? user);
  }
}

void main() {
  late _FakeUserRepository repository;
  late UserBloc bloc;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    repository = _FakeUserRepository();
    bloc = UserBloc(repository: repository);
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
    bloc.close();
  });

  group('UserState Tests', () {
    test('initial state is correct', () {
      expect(bloc.state, const UserState());
    });

    test('UserState copyWith test', () {
      const user = UserEntity(id: "1", firstName: "Test");
      const users = [UserEntity(id: "1", firstName: "Test")];

      expect(
        const UserState().copyWith(status: UserStatus.success, data: user, userList: users, err: "error"),
        const UserState(status: UserStatus.success, data: user, userList: users, err: "error"),
      );
    });

    test('UserState props test', () {
      const user = UserEntity(id: "1", firstName: "Test");
      const users = [UserEntity(id: "1", firstName: "Test")];

      expect(const UserState(status: UserStatus.loading, data: user, userList: users, err: "error").props, [
        UserStatus.loading,
        user,
        users,
        "error",
      ]);
    });
  });

  group('UserEvent equality and props', () {
    test('base UserEvent supports value equality', () {
      const event1 = UserEvent();
      const event2 = UserEvent();
      expect(event1, equals(event2));
    });

    test('base UserEvent props is empty list', () {
      const event = UserEvent();
      expect(event.props, <Object>[]);
    });

    test('UserSearchEvent supports value equality with same parameters', () {
      const event1 = UserSearchEvent(page: 1, size: 10, authorities: 'ROLE_USER', name: 'Test');
      const event2 = UserSearchEvent(page: 1, size: 10, authorities: 'ROLE_USER', name: 'Test');
      expect(event1, equals(event2));
    });

    test('UserSearchEvent has default values for page and size', () {
      const event = UserSearchEvent();
      expect(event.page, 0);
      expect(event.size, 10);
      expect(event.authorities, isNull);
      expect(event.name, isNull);
    });

    test('UserSearchEvent props does not include fields (inherits empty)', () {
      const event = UserSearchEvent(page: 1, size: 20, authorities: 'ROLE_ADMIN');
      // UserSearchEvent does not override props, so it inherits empty list
      expect(event.props, <Object>[]);
    });

    test('UserEditorInit supports value equality', () {
      const event1 = UserEditorInit();
      const event2 = UserEditorInit();
      expect(event1, equals(event2));
    });

    test('UserEditorInit props is empty list', () {
      const event = UserEditorInit();
      expect(event.props, <Object>[]);
    });

    test('UserSubmitEvent supports value equality with same user', () {
      const user = UserEntity(id: '1', firstName: 'Test', lastName: 'User');
      const event1 = UserSubmitEvent(user);
      const event2 = UserSubmitEvent(user);
      expect(event1, equals(event2));
    });

    test('UserSubmitEvent is not equal when user differs', () {
      const user1 = UserEntity(id: '1', firstName: 'Test');
      const user2 = UserEntity(id: '2', firstName: 'Other');
      const event1 = UserSubmitEvent(user1);
      const event2 = UserSubmitEvent(user2);
      expect(event1, isNot(equals(event2)));
    });

    test('UserSubmitEvent props contains user', () {
      const user = UserEntity(id: '1', firstName: 'Test');
      const event = UserSubmitEvent(user);
      expect(event.props, [user]);
    });

    test('UserSubmitEvent user getter returns correct value', () {
      const user = UserEntity(id: '1', firstName: 'Test');
      const event = UserSubmitEvent(user);
      expect(event.user, user);
    });

    test('UserFetchEvent supports value equality with same id', () {
      const event1 = UserFetchEvent('1');
      const event2 = UserFetchEvent('1');
      expect(event1, equals(event2));
    });

    test('UserFetchEvent is not equal when id differs', () {
      const event1 = UserFetchEvent('1');
      const event2 = UserFetchEvent('2');
      expect(event1, isNot(equals(event2)));
    });

    test('UserFetchEvent props contains id', () {
      const event = UserFetchEvent('abc');
      expect(event.props, ['abc']);
    });

    test('UserDeleteEvent supports value equality with same id', () {
      const event1 = UserDeleteEvent('1');
      const event2 = UserDeleteEvent('1');
      expect(event1, equals(event2));
    });

    test('UserDeleteEvent is not equal when id differs', () {
      const event1 = UserDeleteEvent('1');
      const event2 = UserDeleteEvent('2');
      expect(event1, isNot(equals(event2)));
    });

    test('UserDeleteEvent props contains id', () {
      const event = UserDeleteEvent('xyz');
      expect(event.props, ['xyz']);
    });

    test('UserSaveCompleteEvent supports value equality', () {
      const event1 = UserSaveCompleteEvent();
      const event2 = UserSaveCompleteEvent();
      expect(event1, equals(event2));
    });

    test('UserSaveCompleteEvent props is empty list', () {
      const event = UserSaveCompleteEvent();
      expect(event.props, <Object>[]);
    });

    test('UserViewCompleteEvent supports value equality', () {
      const event1 = UserViewCompleteEvent();
      const event2 = UserViewCompleteEvent();
      expect(event1, equals(event2));
    });

    test('UserViewCompleteEvent props is empty list', () {
      const event = UserViewCompleteEvent();
      expect(event.props, <Object>[]);
    });

    test('different event types are not equal', () {
      const fetch = UserFetchEvent('1');
      const delete = UserDeleteEvent('1');
      const submit = UserSubmitEvent(UserEntity(id: '1'));
      const editorInit = UserEditorInit();
      const saveComplete = UserSaveCompleteEvent();
      const viewComplete = UserViewCompleteEvent();

      expect(fetch, isNot(equals(delete)));
      expect(fetch, isNot(equals(submit)));
      expect(editorInit, isNot(equals(saveComplete)));
      expect(saveComplete, isNot(equals(viewComplete)));
    });

    test('all event types are subclasses of UserEvent', () {
      expect(const UserSearchEvent(), isA<UserEvent>());
      expect(const UserEditorInit(), isA<UserEvent>());
      expect(const UserSubmitEvent(UserEntity(id: '1')), isA<UserEvent>());
      expect(const UserFetchEvent('1'), isA<UserEvent>());
      expect(const UserDeleteEvent('1'), isA<UserEvent>());
      expect(const UserSaveCompleteEvent(), isA<UserEvent>());
      expect(const UserViewCompleteEvent(), isA<UserEvent>());
    });
  });

  group('UserBloc Event Tests', () {
    const testUser = UserEntity(id: "1", firstName: "Test", lastName: "User", email: "test@test.com");

    const newUser = UserEntity(firstName: "New", lastName: "User", email: "new@test.com");

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits success state when creating new user',
      setUp: () {
        repository.retrieveResult = testUser;
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(newUser)),
      expect: () => [
        isA<UserState>().having((state) => state.status, 'status', UserStatus.loading),
        isA<UserState>()
            .having((state) => state.status, 'status', UserStatus.saveSuccess)
            .having((state) => state.data, 'data', testUser),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits success state when updating existing user',
      setUp: () {
        repository.retrieveResult = testUser;
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(testUser)),
      expect: () => [
        isA<UserState>().having((state) => state.status, 'status', UserStatus.loading),
        isA<UserState>()
            .having((state) => state.status, 'status', UserStatus.saveSuccess)
            .having((state) => state.data, 'data', testUser),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits failure state on create error',
      setUp: () {
        repository.failure = const UnknownError('Failed to create user');
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(newUser)),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.failure, err: "Failed to create user"),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits failure state on update error',
      setUp: () {
        repository.failure = const UnknownError('Failed to update user');
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(testUser)),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.failure, err: "Failed to update user"),
      ],
    );

    group('UserSearchEvent Tests', () {
      const users = [
        UserEntity(id: "1", firstName: "Test", lastName: "User"),
        UserEntity(id: "2", firstName: "Test2", lastName: "User2"),
      ];

      blocTest<UserBloc, UserState>(
        'emits success state when search by authority is successful',
        setUp: () {
          repository.listResult = users;
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserSearchEvent(authorities: "ROLE_USER")),
        expect: () => [
          const UserState(status: UserStatus.loading),
          const UserState(status: UserStatus.searchSuccess, userList: users),
        ],
      );

      blocTest<UserBloc, UserState>(
        'emits success state when search by name and role is successful',
        setUp: () {
          repository.listResult = users;
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserSearchEvent(name: "Test", authorities: "ROLE_USER")),
        expect: () => [
          const UserState(status: UserStatus.loading),
          const UserState(status: UserStatus.searchSuccess, userList: users),
        ],
      );

      blocTest<UserBloc, UserState>(
        'emits failure state when search fails',
        setUp: () {
          repository.failure = const UnknownError('Search failed');
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserSearchEvent(authorities: "ROLE_USER")),
        expect: () => [
          const UserState(status: UserStatus.loading),
          const UserState(status: UserStatus.failure, err: "Search failed"),
        ],
      );
    });

    group('UserFetchEvent Tests', () {
      blocTest<UserBloc, UserState>(
        'emits success state when fetch is successful',
        setUp: () {
          repository.retrieveResult = testUser;
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserFetchEvent("1")),
        expect: () => [
          const UserState(status: UserStatus.loading),
          const UserState(status: UserStatus.fetchSuccess, data: testUser),
        ],
      );

      blocTest<UserBloc, UserState>(
        'emits failure state when fetch fails',
        setUp: () {
          repository.failure = const UnknownError('Fetch failed');
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserFetchEvent("1")),
        expect: () => [
          const UserState(status: UserStatus.loading),
          const UserState(status: UserStatus.failure, err: "Fetch failed"),
        ],
      );
    });

    group('UserDeleteEvent Tests', () {
      blocTest<UserBloc, UserState>(
        'emits success state when delete is successful',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserDeleteEvent("2")),
        expect: () => [const UserState(status: UserStatus.loading), const UserState(status: UserStatus.deleteSuccess)],
      );

      blocTest<UserBloc, UserState>(
        'emits failure state when trying to delete admin user',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserDeleteEvent("user-1")),
        expect: () => [
          const UserState(status: UserStatus.loading),
          const UserState(status: UserStatus.failure, err: "Admin user cannot be deleted"),
        ],
      );

      blocTest<UserBloc, UserState>(
        'emits failure state when delete fails',
        setUp: () {
          repository.failure = const UnknownError('Delete failed');
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserDeleteEvent("2")),
        expect: () => [
          const UserState(status: UserStatus.loading),
          const UserState(status: UserStatus.failure, err: "Delete failed"),
        ],
      );
    });

    group('UserEditorInit Tests', () {
      blocTest<UserBloc, UserState>(
        'emits initial state when editor is initialized',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserEditorInit()),
        expect: () => [const UserState()],
      );
    });

    group('UserViewCompleteEvent Tests', () {
      blocTest<UserBloc, UserState>(
        'emits viewSuccess state when view is completed',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserViewCompleteEvent()),
        expect: () => [const UserState(status: UserStatus.viewSuccess)],
      );
    });

    group('UserSaveCompleteEvent Tests', () {
      blocTest<UserBloc, UserState>(
        'emits saveSuccess state when save is completed',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserSaveCompleteEvent()),
        expect: () => [const UserState(status: UserStatus.saveSuccess)],
      );
    });
  });
}
