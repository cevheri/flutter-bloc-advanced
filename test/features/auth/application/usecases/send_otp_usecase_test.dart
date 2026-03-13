import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIAuthRepository mockRepo;
  late SendOtpUseCase useCase;

  setUpAll(() => registerAllFallbackValues());

  setUp(() {
    mockRepo = MockIAuthRepository();
    useCase = SendOtpUseCase(mockRepo);
  });

  const request = SendOtpEntity(email: 'test@test.com');

  test('returns Success when OTP sent', () async {
    when(() => mockRepo.sendOtp(any())).thenAnswer((_) async => const Success(null));

    final result = await useCase.call(request);

    expect(result, isA<Success<void>>());
    verify(() => mockRepo.sendOtp(request)).called(1);
  });

  test('returns Failure on error', () async {
    when(() => mockRepo.sendOtp(any())).thenAnswer((_) async => const Failure(NetworkError('Timeout')));

    final result = await useCase.call(request);

    expect(result, isA<Failure<void>>());
  });
}
