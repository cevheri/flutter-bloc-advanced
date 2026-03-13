import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/logout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIAuthRepository mockRepo;
  late LogoutUseCase useCase;

  setUp(() {
    mockRepo = MockIAuthRepository();
    useCase = LogoutUseCase(mockRepo);
  });

  test('returns Success when logout succeeds', () async {
    when(() => mockRepo.logout()).thenAnswer((_) async => const Success(null));

    final result = await useCase.call();

    expect(result, isA<Success<void>>());
    verify(() => mockRepo.logout()).called(1);
  });

  test('returns Failure on error', () async {
    when(() => mockRepo.logout()).thenAnswer((_) async => const Failure(UnknownError('Error')));

    final result = await useCase.call();

    expect(result, isA<Failure<void>>());
  });
}
