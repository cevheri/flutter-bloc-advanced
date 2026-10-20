import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/delete_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/search_users_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/user_list_bloc.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserRepository implements IUserRepository {
  List<UserEntity> listResult = const [];
  AppError? failure;

  /// Thrown instead of returning a result, like a repository bug would.
  Object? thrown;

  @override
  Future<Result<UserEntity>> create(UserEntity user) async => throw UnimplementedError();

  @override
  Future<Result<void>> delete(String id) async {
    if (thrown != null) throw thrown!;
    if (failure != null) return Failure(failure!);
    return const Success(null);
  }

  @override
  Future<Result<List<UserEntity>>> list({int page = 0, int size = 10, List<String> sort = const ['id,desc']}) async {
    if (thrown != null) throw thrown!;
    if (failure != null) return Failure(failure!);
    return Success(listResult);
  }

  @override
  Future<Result<List<UserEntity>>> listByAuthority(int page, int size, String authority) async {
    if (failure != null) return Failure(failure!);
    return Success(listResult);
  }

  @override
  Future<Result<List<UserEntity>>> listByName(int page, int size, String name) async {
    if (failure != null) return Failure(failure!);
    return Success(listResult);
  }

  @override
  Future<Result<List<UserEntity>>> listByNameAndRole(int page, int size, String name, String authority) async {
    if (failure != null) return Failure(failure!);
    return Success(listResult);
  }

  @override
  Future<Result<UserEntity>> retrieve(String id) async => throw UnimplementedError();

  @override
  Future<Result<UserEntity>> update(UserEntity user) async => throw UnimplementedError();
}

void main() {
  late _FakeUserRepository repository;
  late UserListBloc bloc;

  setUp(() {
    repository = _FakeUserRepository();
    bloc = UserListBloc(
      searchUsersUseCase: SearchUsersUseCase(repository),
      deleteUserUseCase: DeleteUserUseCase(repository),
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('UserListState', () {
    test('UserListInitial equality and props', () {
      expect(const UserListInitial(), const UserListInitial());
      expect(const UserListInitial().props, const <Object?>[]);
    });

    test('UserListLoading equality', () {
      expect(const UserListLoading(), const UserListLoading());
    });

    test('UserListLoaded props', () {
      const users = [UserEntity(id: '1', firstName: 'A', lastName: 'B')];
      expect(const UserListLoaded(users: users).props, const <Object?>[users]);
    });

    test('UserListDeleteSuccess equality', () {
      expect(const UserListDeleteSuccess(), const UserListDeleteSuccess());
    });

    test('UserListLoadFailure carries the error code and UserListDeleteFailure the listed users too', () {
      const users = [UserEntity(id: '1', login: 'a')];
      expect(const UserListLoadFailure(errorCode: AppErrorCode.generic).props, const <Object?>[AppErrorCode.generic]);
      expect(
        const UserListDeleteFailure(errorCode: AppErrorCode.userCannotDeleteAdmin, users: users).props,
        const <Object?>[AppErrorCode.userCannotDeleteAdmin, users],
      );
    });

    test('a load failure is not equal to a delete failure with the same code', () {
      expect(
        const UserListLoadFailure(errorCode: AppErrorCode.generic),
        isNot(const UserListDeleteFailure(errorCode: AppErrorCode.generic, users: [])),
      );
    });
  });

  group('UserListEvent', () {
    test('UserListSearch supports value equality', () {
      expect(
        const UserListSearch(page: 1, size: 10, name: 'a', authorities: 'b'),
        const UserListSearch(page: 1, size: 10, name: 'a', authorities: 'b'),
      );
    });

    test('UserListDelete supports value equality', () {
      expect(const UserListDelete('1'), const UserListDelete('1'));
      expect(const UserListDelete('1'), isNot(const UserListDelete('2')));
    });
  });

  group('UserListBloc', () {
    test('initial state is UserListInitial', () {
      expect(bloc.state, const UserListInitial());
    });

    group('UserListSearch', () {
      const users = [
        UserEntity(id: '1', firstName: 'Test', lastName: 'User'),
        UserEntity(id: '2', firstName: 'Test2', lastName: 'User2'),
      ];

      test('emits [loading, loaded] when search succeeds', () {
        fakeAsync((async) {
          repository.listResult = users;
          final searchBloc = UserListBloc(
            searchUsersUseCase: SearchUsersUseCase(repository),
            deleteUserUseCase: DeleteUserUseCase(repository),
          );
          final states = <UserListState>[];
          final sub = searchBloc.stream.listen(states.add);

          searchBloc.add(const UserListSearch(authorities: 'ROLE_USER'));
          async.elapse(const Duration(seconds: 1));

          expect(states, [const UserListLoading(), const UserListLoaded(users: users)]);

          sub.cancel();
          searchBloc.close();
        });
      });

      test('emits [loading, failure] when search fails', () {
        fakeAsync((async) {
          repository.failure = const UnknownError('Search failed');
          final searchBloc = UserListBloc(
            searchUsersUseCase: SearchUsersUseCase(repository),
            deleteUserUseCase: DeleteUserUseCase(repository),
          );
          final states = <UserListState>[];
          final sub = searchBloc.stream.listen(states.add);

          searchBloc.add(const UserListSearch(authorities: 'ROLE_USER'));
          async.elapse(const Duration(seconds: 1));

          expect(states, [const UserListLoading(), const UserListLoadFailure(errorCode: AppErrorCode.generic)]);

          sub.cancel();
          searchBloc.close();
        });
      });

      test('emits [loading, load failure] and reports the error when the search throws', () {
        final observer = _RecordingBlocObserver();
        final previousObserver = Bloc.observer;
        Bloc.observer = observer;
        addTearDown(() => Bloc.observer = previousObserver);

        fakeAsync((async) {
          repository.thrown = StateError('Unexpected response');
          final searchBloc = UserListBloc(
            searchUsersUseCase: SearchUsersUseCase(repository),
            deleteUserUseCase: DeleteUserUseCase(repository),
          );
          final states = <UserListState>[];
          final sub = searchBloc.stream.listen(states.add);

          searchBloc.add(const UserListSearch());
          async.elapse(const Duration(seconds: 1));

          expect(states, [const UserListLoading(), const UserListLoadFailure(errorCode: AppErrorCode.generic)]);
          expect(observer.errors, [isA<StateError>()]);

          sub.cancel();
          searchBloc.close();
        });
      });

      test('rapid bursts collapse to a single emission pair (debounceRestartable)', () {
        fakeAsync((async) {
          repository.listResult = users;
          final searchBloc = UserListBloc(
            searchUsersUseCase: SearchUsersUseCase(repository),
            deleteUserUseCase: DeleteUserUseCase(repository),
          );
          final states = <UserListState>[];
          final sub = searchBloc.stream.listen(states.add);

          searchBloc.add(const UserListSearch(authorities: 'ROLE_A'));
          searchBloc.add(const UserListSearch(authorities: 'ROLE_B'));
          searchBloc.add(const UserListSearch(authorities: 'ROLE_USER'));
          async.elapse(const Duration(seconds: 1));

          expect(states, [const UserListLoading(), const UserListLoaded(users: users)]);

          sub.cancel();
          searchBloc.close();
        });
      });
    });

    group('UserListDelete', () {
      blocTest<UserListBloc, UserListState>(
        'emits [loading, deleteSuccess] when delete succeeds',
        build: () => bloc,
        act: (b) => b.add(const UserListDelete('2')),
        expect: () => [const UserListLoading(), const UserListDeleteSuccess()],
      );

      blocTest<UserListBloc, UserListState>(
        'emits [loading, failure] when delete fails',
        setUp: () => repository.failure = const UnknownError('Delete failed'),
        build: () => bloc,
        act: (b) => b.add(const UserListDelete('2')),
        expect: () => [
          const UserListLoading(),
          const UserListDeleteFailure(errorCode: AppErrorCode.generic, users: []),
        ],
      );

      // The page shows the users of a failed delete, so the list does not disappear when a delete fails.
      const listed = [UserEntity(id: '1', login: 'admin'), UserEntity(id: '2', login: 'new_user-2')];

      blocTest<UserListBloc, UserListState>(
        'keeps the listed users in the failure when delete fails',
        setUp: () => repository.failure = const UnknownError('Delete failed'),
        build: () => bloc,
        seed: () => const UserListLoaded(users: listed),
        act: (b) => b.add(const UserListDelete('new_user-2')),
        expect: () => [
          const UserListLoading(),
          const UserListDeleteFailure(errorCode: AppErrorCode.generic, users: listed),
        ],
      );

      blocTest<UserListBloc, UserListState>(
        'keeps the listed users when a delete fails again after a failed delete',
        build: () => bloc,
        seed: () => const UserListDeleteFailure(errorCode: AppErrorCode.generic, users: listed),
        act: (b) => b.add(const UserListDelete('admin')),
        expect: () => [
          const UserListLoading(),
          const UserListDeleteFailure(errorCode: AppErrorCode.userCannotDeleteAdmin, users: listed),
        ],
      );

      test('emits [loading, delete failure] and reports the error when the delete throws', () {
        final observer = _RecordingBlocObserver();
        final previousObserver = Bloc.observer;
        Bloc.observer = observer;
        addTearDown(() => Bloc.observer = previousObserver);

        fakeAsync((async) {
          repository.thrown = StateError('Unexpected response');
          final deleteBloc = UserListBloc(
            searchUsersUseCase: SearchUsersUseCase(repository),
            deleteUserUseCase: DeleteUserUseCase(repository),
          );
          final states = <UserListState>[];
          final sub = deleteBloc.stream.listen(states.add);

          deleteBloc.add(const UserListDelete('2'));
          async.flushMicrotasks();

          expect(states, [
            const UserListLoading(),
            const UserListDeleteFailure(errorCode: AppErrorCode.generic, users: []),
          ]);
          expect(observer.errors, [isA<StateError>()]);

          sub.cancel();
          deleteBloc.close();
        });
      });

      // Admin-protection rule lives in DeleteUserUseCase (#73). Verify its
      // error code surfaces through the bloc, so the UI can translate it.
      blocTest<UserListBloc, UserListState>(
        'emits a delete failure with the admin-protection code when deleting the admin',
        build: () => bloc,
        act: (b) => b.add(const UserListDelete('admin')),
        expect: () => [
          const UserListLoading(),
          const UserListDeleteFailure(errorCode: AppErrorCode.userCannotDeleteAdmin, users: []),
        ],
      );
    });
  });
}

/// Records the errors blocs report to [BlocObserver.onError].
class _RecordingBlocObserver extends BlocObserver {
  final errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}
