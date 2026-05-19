import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/delete_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/fetch_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/save_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/search_users_usecase.dart';
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
    bloc = UserBloc(
      searchUsersUseCase: SearchUsersUseCase(repository),
      fetchUserUseCase: FetchUserUseCase(repository),
      saveUserUseCase: SaveUserUseCase(repository),
      deleteUserUseCase: DeleteUserUseCase(repository),
    );
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
    bloc.close();
  });

  group('UserState Tests', () {
    const testUser = UserEntity(id: "1", firstName: "Test");
    const users = [UserEntity(id: "1", firstName: "Test")];

    test('initial state is UserInitial', () {
      expect(bloc.state, const UserInitial());
    });

    test('UserInitial props', () {
      expect(const UserInitial().props, const <Object?>[]);
    });

    test('UserLoading carries optional data forward', () {
      expect(const UserLoading().props, const <Object?>[null]);
      expect(const UserLoading(data: testUser).props, const <Object?>[testUser]);
    });

    test('UserSearchSuccess props', () {
      expect(const UserSearchSuccess(userList: users).props, const <Object?>[users]);
    });

    test('UserFetchSuccess props', () {
      expect(const UserFetchSuccess(data: testUser).props, const <Object?>[testUser]);
    });

    test('UserSaveSuccess props', () {
      expect(const UserSaveSuccess(data: testUser).props, const <Object?>[testUser]);
      expect(const UserSaveSuccess().props, const <Object?>[null]);
    });

    test('UserDeleteSuccess props', () {
      expect(const UserDeleteSuccess().props, const <Object?>[]);
    });

    test('UserViewSuccess props', () {
      expect(const UserViewSuccess(data: testUser).props, const <Object?>[testUser]);
    });

    test('UserFailure props', () {
      expect(const UserFailure(error: "boom").props, const <Object?>["boom"]);
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
      expect: () => [isA<UserLoading>(), isA<UserSaveSuccess>().having((s) => s.data, 'data', testUser)],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits success state when updating existing user',
      setUp: () {
        repository.retrieveResult = testUser;
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(testUser)),
      expect: () => [isA<UserLoading>(), isA<UserSaveSuccess>().having((s) => s.data, 'data', testUser)],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits failure state on create error',
      setUp: () {
        repository.failure = const UnknownError('Failed to create user');
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(newUser)),
      expect: () => [const UserLoading(), UserFailure(error: "Failed to create user")],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits failure state on update error',
      setUp: () {
        repository.failure = const UnknownError('Failed to update user');
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(testUser)),
      expect: () => [const UserLoading(), UserFailure(error: "Failed to update user")],
    );

    group('UserSearchEvent Tests', () {
      const users = [
        UserEntity(id: "1", firstName: "Test", lastName: "User"),
        UserEntity(id: "2", firstName: "Test2", lastName: "User2"),
      ];

      // UserSearchEvent is debounced (EventTransformers.debounceRestartable, 300ms),
      // so each blocTest must wait past that window before checking emissions.
      const debounceWait = Duration(milliseconds: 400);

      blocTest<UserBloc, UserState>(
        'emits success state when search by authority is successful',
        setUp: () {
          repository.listResult = users;
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserSearchEvent(authorities: "ROLE_USER")),
        wait: debounceWait,
        expect: () => [const UserLoading(), UserSearchSuccess(userList: users)],
      );

      blocTest<UserBloc, UserState>(
        'emits success state when search by name and role is successful',
        setUp: () {
          repository.listResult = users;
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserSearchEvent(name: "Test", authorities: "ROLE_USER")),
        wait: debounceWait,
        expect: () => [const UserLoading(), UserSearchSuccess(userList: users)],
      );

      blocTest<UserBloc, UserState>(
        'emits failure state when search fails',
        setUp: () {
          repository.failure = const UnknownError('Search failed');
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserSearchEvent(authorities: "ROLE_USER")),
        wait: debounceWait,
        expect: () => [const UserLoading(), UserFailure(error: "Search failed")],
      );

      // Regression for #76: rapid bursts must collapse into a single
      // emission pair thanks to debounceRestartable. (Uses authorities-
      // only events because the use case has a pre-existing routing
      // issue with name-only searches; out of scope here.)
      blocTest<UserBloc, UserState>(
        'rapid UserSearchEvent bursts are debounced to a single emission pair',
        setUp: () {
          repository.listResult = users;
        },
        build: () => bloc,
        act: (bloc) {
          bloc.add(const UserSearchEvent(authorities: "ROLE_A"));
          bloc.add(const UserSearchEvent(authorities: "ROLE_B"));
          bloc.add(const UserSearchEvent(authorities: "ROLE_C"));
          bloc.add(const UserSearchEvent(authorities: "ROLE_USER"));
        },
        wait: debounceWait,
        // Only the final UserSearchEvent should produce loading + success;
        // intermediate events are discarded by the debounce window.
        expect: () => [const UserLoading(), UserSearchSuccess(userList: users)],
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
        expect: () => [const UserLoading(), UserFetchSuccess(data: testUser)],
      );

      blocTest<UserBloc, UserState>(
        'emits failure state when fetch fails',
        setUp: () {
          repository.failure = const UnknownError('Fetch failed');
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserFetchEvent("1")),
        expect: () => [const UserLoading(), UserFailure(error: "Fetch failed")],
      );
    });

    group('UserDeleteEvent Tests', () {
      blocTest<UserBloc, UserState>(
        'emits success state when delete is successful',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserDeleteEvent("2")),
        expect: () => [const UserLoading(), const UserDeleteSuccess()],
      );

      blocTest<UserBloc, UserState>(
        'emits failure state when trying to delete admin user',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserDeleteEvent("user-1")),
        expect: () => [const UserLoading(), UserFailure(error: "Admin user cannot be deleted")],
      );

      blocTest<UserBloc, UserState>(
        'emits failure state when delete fails',
        setUp: () {
          repository.failure = const UnknownError('Delete failed');
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const UserDeleteEvent("2")),
        expect: () => [const UserLoading(), UserFailure(error: "Delete failed")],
      );
    });

    group('UserEditorInit Tests', () {
      blocTest<UserBloc, UserState>(
        'emits initial state when editor is initialized',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserEditorInit()),
        expect: () => [const UserInitial()],
      );
    });

    group('UserViewCompleteEvent Tests', () {
      blocTest<UserBloc, UserState>(
        'emits UserViewSuccess when view is completed',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserViewCompleteEvent()),
        expect: () => [const UserViewSuccess()],
      );
    });

    group('UserSaveCompleteEvent Tests', () {
      blocTest<UserBloc, UserState>(
        'emits UserSaveSuccess when save is completed',
        build: () => bloc,
        act: (bloc) => bloc.add(const UserSaveCompleteEvent()),
        expect: () => [const UserSaveSuccess()],
      );
    });
  });
}
