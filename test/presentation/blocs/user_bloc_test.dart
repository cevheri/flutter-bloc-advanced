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
  late MockUserRepository repository;
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
        const UserState().copyWith(
          status: UserStatus.success,
          data: user,
          userList: users,
          err: "error",
        ),
        const UserState(
          status: UserStatus.success,
          data: user,
          userList: users,
          err: "error",
        ),
      );
    });

    test('UserState props test', () {
      const user = User(id: "1", firstName: "Test");
      const users = [User(id: "1", firstName: "Test")];

      expect(
        const UserState(
          status: UserStatus.loading,
          data: user,
          userList: users,
          err: "error",
        ).props,
        [UserStatus.loading, user, users, "error"],
      );
    });
  });

  group('UserBloc Event Tests', () {
    const testUser = User(
      id: "1",
      firstName: "Test",
      lastName: "User",
      email: "test@test.com",
    );

    const newUser = User(
      firstName: "New",
      lastName: "User",
      email: "new@test.com",
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits success state when creating new user',
      setUp: () {
        when(repository.create(newUser)).thenAnswer((_) async => testUser);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(newUser)),
      expect: () => [
        isA<UserState>().having((state) => state.status, 'status', UserStatus.loading),
        isA<UserState>().having((state) => state.status, 'status', UserStatus.saveSuccess).having((state) => state.data, 'data', testUser),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits success state when updating existing user',
      setUp: () {
        when(repository.update(testUser)).thenAnswer((_) async => testUser);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(testUser)),
      expect: () => [
        isA<UserState>().having((state) => state.status, 'status', UserStatus.loading),
        isA<UserState>().having((state) => state.status, 'status', UserStatus.saveSuccess).having((state) => state.data, 'data', testUser),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits failure state on create error',
      setUp: () {
        when(repository.create(newUser)).thenThrow(Exception('Failed to create user'));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(newUser)),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.failure),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserSubmitEvent emits failure state on update error',
      setUp: () {
        when(repository.update(testUser)).thenThrow(Exception('Failed to update user'));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UserSubmitEvent(testUser)),
      expect: () => [
        const UserState(status: UserStatus.loading),
        const UserState(status: UserStatus.failure),
      ],
    );
  });
}
