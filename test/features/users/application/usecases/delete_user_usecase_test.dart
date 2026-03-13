import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/delete_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIUserRepository mockRepo;
  late DeleteUserUseCase useCase;

  setUp(() {
    mockRepo = MockIUserRepository();
    useCase = DeleteUserUseCase(mockRepo);
  });

  test('returns Success when delete succeeds', () async {
    when(() => mockRepo.delete('1')).thenAnswer((_) async => const Success(null));

    final result = await useCase.call('1');

    expect(result, isA<Success<void>>());
    verify(() => mockRepo.delete('1')).called(1);
  });

  test('returns Failure when delete fails', () async {
    when(() => mockRepo.delete('1')).thenAnswer((_) async => const Failure(ServerError('Error')));

    final result = await useCase.call('1');

    expect(result, isA<Failure<void>>());
  });
}
