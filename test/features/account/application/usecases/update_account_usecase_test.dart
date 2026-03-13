import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/update_account_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIAccountRepository mockRepo;
  late UpdateAccountUseCase useCase;

  setUpAll(() => registerAllFallbackValues());

  setUp(() {
    mockRepo = MockIAccountRepository();
    useCase = UpdateAccountUseCase(mockRepo);
  });

  const testUser = UserEntity(id: '1', login: 'admin', email: 'admin@test.com');

  test('returns Success when update succeeds', () async {
    when(() => mockRepo.update(any())).thenAnswer((_) async => const Success(testUser));

    final result = await useCase.call(testUser);

    expect(result, isA<Success<UserEntity>>());
    verify(() => mockRepo.update(testUser)).called(1);
  });

  test('returns Failure on error', () async {
    when(() => mockRepo.update(any())).thenAnswer((_) async => const Failure(ValidationError('Invalid')));

    final result = await useCase.call(testUser);

    expect(result, isA<Failure<UserEntity>>());
  });
}
