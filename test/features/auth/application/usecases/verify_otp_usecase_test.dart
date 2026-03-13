import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIAuthRepository mockRepo;
  late VerifyOtpUseCase useCase;

  setUpAll(() => registerAllFallbackValues());

  setUp(() {
    mockRepo = MockIAuthRepository();
    useCase = VerifyOtpUseCase(mockRepo);
  });

  const request = VerifyOtpEntity(email: 'test@test.com', otp: '123456');
  const token = AuthTokenEntity(idToken: 'jwt-token');

  test('returns Success with token on valid OTP', () async {
    when(() => mockRepo.verifyOtp(any())).thenAnswer((_) async => const Success(token));

    final result = await useCase.call(request);

    expect(result, isA<Success<AuthTokenEntity>>());
    verify(() => mockRepo.verifyOtp(request)).called(1);
  });

  test('returns Failure on invalid OTP', () async {
    when(() => mockRepo.verifyOtp(any())).thenAnswer((_) async => const Failure(ValidationError('Invalid OTP')));

    final result = await useCase.call(request);

    expect(result, isA<Failure<AuthTokenEntity>>());
  });
}
