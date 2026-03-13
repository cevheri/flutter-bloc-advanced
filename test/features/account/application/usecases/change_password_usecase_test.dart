import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/change_password_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIAccountRepository mockRepo;
  late ChangePasswordUseCase useCase;

  setUpAll(() => registerAllFallbackValues());

  setUp(() {
    mockRepo = MockIAccountRepository();
    useCase = ChangePasswordUseCase(mockRepo);
  });

  const dto = PasswordChangeDTO(currentPassword: 'old', newPassword: 'new');

  test('returns Success when change succeeds', () async {
    when(() => mockRepo.changePassword(any())).thenAnswer((_) async => const Success(null));

    final result = await useCase.call(dto);

    expect(result, isA<Success<void>>());
    verify(() => mockRepo.changePassword(dto)).called(1);
  });

  test('returns Failure on error', () async {
    when(() => mockRepo.changePassword(any())).thenAnswer((_) async => const Failure(AuthError('Wrong password')));

    final result = await useCase.call(dto);

    expect(result, isA<Failure<void>>());
  });
}
