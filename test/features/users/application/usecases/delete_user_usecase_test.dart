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

  // Regression coverage for #73: the admin-protection rule now lives in
  // the use case, not in UserBloc.
  test('rejects deletion of the protected admin user (user-1) without hitting repo', () async {
    final result = await useCase.call('user-1');

    expect(result, isA<Failure<void>>());
    expect((result as Failure).error, isA<ValidationError>());
    expect(result.error.message, 'Admin user cannot be deleted');
    verifyNever(() => mockRepo.delete(any()));
  });
}
