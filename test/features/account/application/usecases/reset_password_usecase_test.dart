import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/reset_password_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIAccountRepository mockRepo;
  late ResetPasswordUseCase useCase;

  setUp(() {
    mockRepo = MockIAccountRepository();
    useCase = ResetPasswordUseCase(mockRepo);
  });

  test('returns Success when reset succeeds', () async {
    when(() => mockRepo.resetPassword('test@test.com')).thenAnswer((_) async => const Success(null));

    final result = await useCase.call('test@test.com');

    expect(result, isA<Success<void>>());
    verify(() => mockRepo.resetPassword('test@test.com')).called(1);
  });

  test('returns Failure on error', () async {
    when(() => mockRepo.resetPassword('bad')).thenAnswer((_) async => const Failure(ValidationError('Invalid email')));

    final result = await useCase.call('bad');

    expect(result, isA<Failure<void>>());
  });
}
