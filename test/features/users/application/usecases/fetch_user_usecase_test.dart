import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/fetch_user_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIUserRepository mockRepo;
  late FetchUserUseCase useCase;

  setUp(() {
    mockRepo = MockIUserRepository();
    useCase = FetchUserUseCase(mockRepo);
  });

  const testUser = UserEntity(id: '1', login: 'test', email: 'test@test.com');

  test('returns Success when repository returns user', () async {
    when(() => mockRepo.retrieve('1')).thenAnswer((_) async => const Success(testUser));

    final result = await useCase.call('1');

    expect(result, isA<Success<UserEntity>>());
    expect((result as Success).data, testUser);
    verify(() => mockRepo.retrieve('1')).called(1);
  });

  test('returns Failure when repository returns failure', () async {
    when(() => mockRepo.retrieve('1')).thenAnswer((_) async => const Failure(NotFoundError('Not found')));

    final result = await useCase.call('1');

    expect(result, isA<Failure<UserEntity>>());
    expect((result as Failure).error, isA<NotFoundError>());
  });
}
