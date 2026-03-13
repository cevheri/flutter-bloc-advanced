import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/save_user_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIUserRepository mockRepo;
  late SaveUserUseCase useCase;

  setUpAll(() => registerAllFallbackValues());

  setUp(() {
    mockRepo = MockIUserRepository();
    useCase = SaveUserUseCase(mockRepo);
  });

  const newUser = UserEntity(login: 'new', email: 'new@test.com');
  const existingUser = UserEntity(id: '1', login: 'existing', email: 'existing@test.com');

  test('calls create when user has no id', () async {
    when(() => mockRepo.create(any())).thenAnswer((_) async => Success(newUser.copyWith(id: '2')));

    final result = await useCase.call(newUser);

    expect(result, isA<Success<UserEntity>>());
    verify(() => mockRepo.create(newUser)).called(1);
    verifyNever(() => mockRepo.update(any()));
  });

  test('calls update when user has an id', () async {
    when(() => mockRepo.update(any())).thenAnswer((_) async => const Success(existingUser));

    final result = await useCase.call(existingUser);

    expect(result, isA<Success<UserEntity>>());
    verify(() => mockRepo.update(existingUser)).called(1);
    verifyNever(() => mockRepo.create(any()));
  });

  test('returns Failure on error', () async {
    when(() => mockRepo.create(any())).thenAnswer((_) async => const Failure(ValidationError('Invalid')));

    final result = await useCase.call(newUser);

    expect(result, isA<Failure<UserEntity>>());
  });
}
