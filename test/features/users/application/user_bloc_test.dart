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
