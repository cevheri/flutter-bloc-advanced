import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/search_users_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIUserRepository mockRepo;
  late SearchUsersUseCase useCase;

  setUp(() {
    mockRepo = MockIUserRepository();
    useCase = SearchUsersUseCase(mockRepo);
  });

  const users = [UserEntity(id: '1', login: 'test')];

  test('calls list() when no name or authority provided', () async {
    when(() => mockRepo.list(page: 0, size: 10)).thenAnswer((_) async => const Success(users));

    final result = await useCase.call(const SearchUsersParams());

    expect(result, isA<Success<List<UserEntity>>>());
    verify(() => mockRepo.list(page: 0, size: 10)).called(1);
  });

  test('calls list() when name and authority are empty strings', () async {
    when(() => mockRepo.list(page: 0, size: 10)).thenAnswer((_) async => const Success(users));

    final result = await useCase.call(const SearchUsersParams(name: '', authorities: ''));

    expect(result, isA<Success<List<UserEntity>>>());
    verify(() => mockRepo.list(page: 0, size: 10)).called(1);
  });

  test('calls listByNameAndRole() when both name and authority provided', () async {
    when(() => mockRepo.listByNameAndRole(0, 10, 'John', 'ROLE_USER')).thenAnswer((_) async => const Success(users));

    final result = await useCase.call(const SearchUsersParams(name: 'John', authorities: 'ROLE_USER'));

    expect(result, isA<Success<List<UserEntity>>>());
    verify(() => mockRepo.listByNameAndRole(0, 10, 'John', 'ROLE_USER')).called(1);
  });

  test('calls listByAuthority() when only authority provided', () async {
    when(() => mockRepo.listByAuthority(0, 10, 'ROLE_ADMIN')).thenAnswer((_) async => const Success(users));

    final result = await useCase.call(const SearchUsersParams(authorities: 'ROLE_ADMIN'));

    expect(result, isA<Success<List<UserEntity>>>());
    verify(() => mockRepo.listByAuthority(0, 10, 'ROLE_ADMIN')).called(1);
  });

  test('passes custom page and size', () async {
    when(() => mockRepo.list(page: 2, size: 20)).thenAnswer((_) async => const Success(users));

    await useCase.call(const SearchUsersParams(page: 2, size: 20));

    verify(() => mockRepo.list(page: 2, size: 20)).called(1);
  });

  test('returns Failure on error', () async {
    when(() => mockRepo.list(page: 0, size: 10)).thenAnswer((_) async => const Failure(NetworkError('Error')));

    final result = await useCase.call(const SearchUsersParams());

    expect(result, isA<Failure<List<UserEntity>>>());
  });
}
