import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/register_account_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIAccountRepository mockRepo;
  late RegisterAccountUseCase useCase;

  setUpAll(() => registerAllFallbackValues());

  setUp(() {
    mockRepo = MockIAccountRepository();
    useCase = RegisterAccountUseCase(mockRepo);
  });

  const newUser = UserEntity(login: 'new', email: 'new@test.com');

  test('returns Success when registration succeeds', () async {
    when(() => mockRepo.register(any())).thenAnswer((_) async => Success(newUser.copyWith(id: '1')));

    final result = await useCase.call(newUser);

    expect(result, isA<Success<UserEntity>>());
    verify(() => mockRepo.register(newUser)).called(1);
  });

  test('returns Failure on error', () async {
    when(() => mockRepo.register(any())).thenAnswer((_) async => const Failure(ValidationError('Email exists')));

    final result = await useCase.call(newUser);

    expect(result, isA<Failure<UserEntity>>());
  });
}
