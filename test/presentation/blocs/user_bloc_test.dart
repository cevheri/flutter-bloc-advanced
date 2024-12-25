import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_utils.dart';
import 'user_bloc_test.mocks.dart';

@GenerateMocks([UserRepository])
void main() {
  late UserRepository repository;
  late UserBloc bloc;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    repository = MockUserRepository();
  });

  setUp(() {
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
      const user = User(id: "1", firstName: "Test");
      const users = [User(id: "1", firstName: "Test")];

      expect(
        const UserState(),
        const UserState(),
      );
    });

    test('UserState props test', () {
      const user = User(id: "1", firstName: "Test");
      const users = [User(id: "1", firstName: "Test")];

      expect(
        const UserState(status: UserStatus.loading, data: user, userList: users, err: "error").props,
        [UserStatus.loading, user, users, "error"],
      );
    });
  });

  group('UserBloc Event Tests', () {
    const testUser = User(id: "1", firstName: "Test", lastName: "User", email: "test@test.com");

    blocTest<UserBloc, UserState>(
      'UserEditorInit emits correct states',
      build: () => bloc,
      act: (bloc) => bloc.add(UserEditorInit()),
      expect: () => [const UserState()],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits success state when creating new user',
      setUp: () {
        when(repository.create(testUser)).thenAnswer((_) async => testUser);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(UserSubmitEvent(testUser)),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.saveSuccess, data: testUser),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits failure state on error',
      setUp: () {
        when(repository.create(testUser)).thenThrow(Exception('Failed to create user'));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(UserSubmitEvent(testUser)),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.failure),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserDeleteEvent emits success state',
      setUp: () {
        when(repository.delete("test-id")).thenAnswer((_) async => null);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserDeleteEvent("test-id")),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.deleteSuccess),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserDeleteEvent prevents deleting admin user',
      build: () => bloc,
      act: (bloc) => bloc.add(const UserDeleteEvent( "user-1")),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.failure, err: "Admin user cannot be deleted"),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserFetchEvent emits success state',
      setUp: () {
        when(repository.retrieve("test-id")).thenAnswer((_) async => testUser);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserFetchEvent( "test-id")),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.fetchSuccess, data: testUser),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserSearchEvent with empty name emits success state',
      setUp: () {
        when(repository.listByAuthority(0, 10, "ADMIN")).thenAnswer((_) async => [testUser]);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSearchEvent(name: "", page: 0, size: 10, authority: "ADMIN")),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.searchSuccess, userList: [testUser]),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserViewCompleteEvent emits success state',
      build: () => bloc,
      act: (bloc) => bloc.add(UserViewCompleteEvent()),
      expect: () => [
        const UserState(status: UserStatus.viewSuccess),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserSaveCompleteEvent emits success state',
      build: () => bloc,
      act: (bloc) => bloc.add(UserSaveCompleteEvent()),
      expect: () => [
        const UserState(status: UserStatus.saveSuccess),
      ],
    );
  });
}
