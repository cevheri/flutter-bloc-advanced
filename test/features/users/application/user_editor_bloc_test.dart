import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/fetch_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/save_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/user_editor_bloc.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserRepository implements IUserRepository {
  UserEntity? retrieveResult;
  AppError? failure;

  @override
  Future<Result<UserEntity>> create(UserEntity user) async {
    if (failure != null) return Failure(failure!);
    return Success(retrieveResult ?? user);
  }

  @override
  Future<Result<void>> delete(String id) async => throw UnimplementedError();

  @override
  Future<Result<List<UserEntity>>> list({int page = 0, int size = 10, List<String> sort = const ['id,desc']}) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<UserEntity>>> listByAuthority(int page, int size, String authority) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<UserEntity>>> listByNameAndRole(int page, int size, String name, String authority) async =>
      throw UnimplementedError();

  @override
  Future<Result<UserEntity>> retrieve(String id) async {
    if (failure != null) return Failure(failure!);
    return Success(retrieveResult!);
  }

  @override
  Future<Result<UserEntity>> retrieveByLogin(String login) async => throw UnimplementedError();

  @override
  Future<Result<UserEntity>> update(UserEntity user) async {
    if (failure != null) return Failure(failure!);
    return Success(retrieveResult ?? user);
  }
}

void main() {
  late _FakeUserRepository repository;
  late UserEditorBloc bloc;

  const sampleUser = UserEntity(id: '1', firstName: 'Test', lastName: 'User');

  setUp(() {
    repository = _FakeUserRepository();
    bloc = UserEditorBloc(fetchUserUseCase: FetchUserUseCase(repository), saveUserUseCase: SaveUserUseCase(repository));
  });

  tearDown(() {
    bloc.close();
  });

  group('UserEditorState', () {
    test('UserEditorInitial equality', () {
      expect(const UserEditorInitial(), const UserEditorInitial());
    });

    test('UserEditorLoading carries optional data forward', () {
      expect(const UserEditorLoading(data: sampleUser).props, const <Object?>[sampleUser]);
      expect(const UserEditorLoading().props, const <Object?>[null]);
    });

    test('UserEditorLoaded props', () {
      expect(const UserEditorLoaded(data: sampleUser).props, const <Object?>[sampleUser]);
    });

    test('UserEditorSaved / UserEditorViewed carry optional data', () {
      expect(const UserEditorSaved(data: sampleUser).props, const <Object?>[sampleUser]);
      expect(const UserEditorViewed(data: sampleUser).props, const <Object?>[sampleUser]);
    });

    test('UserEditorFailure props', () {
      expect(const UserEditorFailure(error: 'boom').props, const <Object?>['boom']);
    });
  });

  group('UserEditorEvent', () {
    test('UserEditorFetch equality', () {
      expect(const UserEditorFetch('1'), const UserEditorFetch('1'));
      expect(const UserEditorFetch('1'), isNot(const UserEditorFetch('2')));
    });

    test('UserEditorSubmit equality', () {
      expect(const UserEditorSubmit(sampleUser), const UserEditorSubmit(sampleUser));
    });

    test('UserEditorReset / SaveComplete / ViewComplete are singletons by value', () {
      expect(const UserEditorReset(), const UserEditorReset());
      expect(const UserEditorSaveComplete(), const UserEditorSaveComplete());
      expect(const UserEditorViewComplete(), const UserEditorViewComplete());
    });
  });

  group('UserEditorBloc', () {
    test('initial state is UserEditorInitial', () {
      expect(bloc.state, const UserEditorInitial());
    });

    group('UserEditorReset', () {
      blocTest<UserEditorBloc, UserEditorState>(
        'emits UserEditorInitial',
        build: () => bloc,
        act: (b) => b.add(const UserEditorReset()),
        expect: () => [const UserEditorInitial()],
      );
    });

    group('UserEditorFetch', () {
      blocTest<UserEditorBloc, UserEditorState>(
        'emits [loading, loaded] when fetch succeeds',
        setUp: () => repository.retrieveResult = sampleUser,
        build: () => bloc,
        act: (b) => b.add(const UserEditorFetch('1')),
        expect: () => [const UserEditorLoading(), const UserEditorLoaded(data: sampleUser)],
      );

      blocTest<UserEditorBloc, UserEditorState>(
        'emits [loading, failure] when fetch fails',
        setUp: () => repository.failure = const UnknownError('Fetch failed'),
        build: () => bloc,
        act: (b) => b.add(const UserEditorFetch('1')),
        expect: () => [const UserEditorLoading(), const UserEditorFailure(error: 'Fetch failed')],
      );
    });

    group('UserEditorSubmit', () {
      blocTest<UserEditorBloc, UserEditorState>(
        'emits [loading, saved] when submit succeeds',
        setUp: () => repository.retrieveResult = sampleUser,
        build: () => bloc,
        act: (b) => b.add(const UserEditorSubmit(sampleUser)),
        expect: () => [const UserEditorLoading(), const UserEditorSaved(data: sampleUser)],
      );

      blocTest<UserEditorBloc, UserEditorState>(
        'emits [loading, failure] when submit fails',
        setUp: () => repository.failure = const UnknownError('Save failed'),
        build: () => bloc,
        act: (b) => b.add(const UserEditorSubmit(sampleUser)),
        expect: () => [const UserEditorLoading(), const UserEditorFailure(error: 'Save failed')],
      );

      blocTest<UserEditorBloc, UserEditorState>(
        'submit carries data forward in the loading state from a loaded editor',
        setUp: () => repository.retrieveResult = sampleUser,
        build: () => bloc,
        seed: () => const UserEditorLoaded(data: sampleUser),
        act: (b) => b.add(const UserEditorSubmit(sampleUser)),
        expect: () => [const UserEditorLoading(data: sampleUser), const UserEditorSaved(data: sampleUser)],
      );
    });

    group('UserEditorSaveComplete / UserEditorViewComplete', () {
      blocTest<UserEditorBloc, UserEditorState>(
        'SaveComplete preserves the carried user',
        build: () => bloc,
        seed: () => const UserEditorLoaded(data: sampleUser),
        act: (b) => b.add(const UserEditorSaveComplete()),
        expect: () => [const UserEditorSaved(data: sampleUser)],
      );

      blocTest<UserEditorBloc, UserEditorState>(
        'ViewComplete preserves the carried user',
        build: () => bloc,
        seed: () => const UserEditorLoaded(data: sampleUser),
        act: (b) => b.add(const UserEditorViewComplete()),
        expect: () => [const UserEditorViewed(data: sampleUser)],
      );
    });
  });
}
