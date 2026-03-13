import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockIAuthRepository mockRepo;
  late AuthenticateUserUseCase useCase;

  setUpAll(() => registerAllFallbackValues());

  setUp(() {
    mockRepo = MockIAuthRepository();
    useCase = AuthenticateUserUseCase(mockRepo);
  });

  const credentials = AuthCredentialsEntity(username: 'admin', password: 'pass');
  const token = AuthTokenEntity(idToken: 'jwt-token');

  test('returns Success with token on valid credentials', () async {
    when(() => mockRepo.authenticate(any())).thenAnswer((_) async => const Success(token));

    final result = await useCase.call(credentials);

    expect(result, isA<Success<AuthTokenEntity>>());
    expect((result as Success).data.idToken, 'jwt-token');
    verify(() => mockRepo.authenticate(credentials)).called(1);
  });

  test('returns Failure on auth error', () async {
    when(() => mockRepo.authenticate(any())).thenAnswer((_) async => const Failure(AuthError('Bad credentials')));

    final result = await useCase.call(credentials);

    expect(result, isA<Failure<AuthTokenEntity>>());
  });
}
